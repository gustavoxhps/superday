import CoreData
import RxSwift
import Foundation
import CoreLocation

class DefaultTimeSlotService : TimeSlotService
{
    // MARK: Fields
    private let timeService : TimeService
    private let loggingService : LoggingService
    private let locationService : LocationService
    private let persistencyService : BasePersistencyService<TimeSlot>
    
    private let timeSlotCreatedVariable = Variable(TimeSlot(withStartTime: Date(),
                                                            category: .unknown,
                                                            categoryWasSetByUser: false))
    
    private let timeSlotUpdatedVariable = Variable(TimeSlot(withStartTime: Date(),
                                                            category: .unknown,
                                                            categoryWasSetByUser: false))
    
    // MARK: Properties
    init(timeService: TimeService,
         loggingService: LoggingService,
         locationService: LocationService,
         persistencyService: BasePersistencyService<TimeSlot>)
    {
        self.timeService = timeService
        self.loggingService = loggingService
        self.locationService = locationService
        self.persistencyService = persistencyService

        self.timeSlotCreatedObservable = timeSlotCreatedVariable.asObservable().skip(1)
        self.timeSlotUpdatedObservable = timeSlotUpdatedVariable.asObservable().skip(1)
    }
    
    // MARK: Properties
    let timeSlotCreatedObservable : Observable<TimeSlot>
    let timeSlotUpdatedObservable : Observable<TimeSlot>

    // MARK: Methods
    @discardableResult func addTimeSlot(withStartTime startTime: Date, category: Category, categoryWasSetByUser: Bool, tryUsingLatestLocation: Bool) -> TimeSlot?
    {
        let location : CLLocation? = tryUsingLatestLocation ? self.locationService.getLastKnownLocation() : nil
        
        return self.addTimeSlot(withStartTime: startTime,
                                category: category,
                                categoryWasSetByUser: categoryWasSetByUser,
                                location: location)
    }
    
    @discardableResult func addTimeSlot(withStartTime startTime: Date, category: Category, categoryWasSetByUser: Bool, location: CLLocation?) -> TimeSlot?
    {
        let timeSlot = TimeSlot(withStartTime: startTime,
                                category: category, 
                                categoryWasSetByUser: categoryWasSetByUser,
                                location: location)
        
        return self.tryAdd(timeSlot: timeSlot)
    }
    
    @discardableResult func addTimeSlot(withStartTime startTime: Date, smartGuess: SmartGuess, location: CLLocation) -> TimeSlot?
    {
        let timeSlot = TimeSlot(withStartTime: startTime,
                                smartGuess: smartGuess,
                                location: location)
        
        return self.tryAdd(timeSlot: timeSlot)
    }
    
    private func tryAdd(timeSlot: TimeSlot) -> TimeSlot?
    {
        //The previous TimeSlot needs to be finished before a new one can start
        guard self.endPreviousTimeSlot(atDate: timeSlot.startTime) && self.persistencyService.create(timeSlot) else
        {
            self.loggingService.log(withLogLevel: .error, message: "Failed to create new TimeSlot")
            return nil
        }
        
        self.loggingService.log(withLogLevel: .info, message: "New TimeSlot with category \"\(timeSlot.category)\" created")
        
        self.timeSlotCreatedVariable.value = timeSlot
        
        return timeSlot
    }
    
    func getTimeSlots(forDay day: Date) -> [TimeSlot]
    {
        let startTime = day.ignoreTimeComponents() as NSDate
        let endTime = day.tomorrow.ignoreTimeComponents() as NSDate
        let predicate = Predicate(parameter: "startTime", rangesFromDate: startTime, toDate: endTime)
        
        let timeSlots = self.persistencyService.get(withPredicate: predicate)
        return timeSlots
    }
    
    func update(timeSlot: TimeSlot, withCategory category: Category, setByUser: Bool)
    {
        guard self.canChangeCategory(of: timeSlot, to: category, setByUser: setByUser) else { return }
        
        let predicate = Predicate(parameter: "startTime", equals: timeSlot.startTime as AnyObject)
        let editFunction = { (timeSlot: TimeSlot) -> (TimeSlot) in
            
            timeSlot.categoryWasSetByUser = setByUser
            timeSlot.category = category
            return timeSlot
        }
        
        if self.persistencyService.update(withPredicate: predicate, updateFunction: editFunction)
        {
            timeSlot.category = category
            self.timeSlotUpdatedVariable.value = timeSlot
        }
        else
        {
            self.loggingService.log(withLogLevel: .error, message: "Error updating category of TimeSlot created on \(timeSlot.startTime) from \(timeSlot.category) to \(category)")
        }
    }
    
    private func canChangeCategory(of timeSlot : TimeSlot, to category : Category, setByUser : Bool) -> Bool
    {
        if setByUser == timeSlot.categoryWasSetByUser
        {
            return category != timeSlot.category
        }
        
        if setByUser
        {
            return true
        }
        
        self.loggingService.log(withLogLevel: .warning, message: "Tried automatically updating category of TimeSlot which was set by user")
        return false
    }
    
    func getLast() -> TimeSlot?
    {
        return self.persistencyService.getLast()
    }
    
    func calculateDuration(ofTimeSlot timeSlot: TimeSlot) -> TimeInterval
    {
        let endTime = self.getEndTime(ofTimeSlot: timeSlot)
        
        return endTime.timeIntervalSince(timeSlot.startTime)
    }
    
    private func getEndTime(ofTimeSlot timeSlot: TimeSlot) -> Date
    {
        if let endTime = timeSlot.endTime { return endTime}
        
        let date = self.timeService.now
        let timeEntryLimit = timeSlot.startTime.tomorrow.ignoreTimeComponents()
        let timeEntryLastedOverOneDay = date > timeEntryLimit
        
        //TimeSlots can't go past midnight
        let endTime = timeEntryLastedOverOneDay ? timeEntryLimit : date
        return endTime
    }
    
    private func endPreviousTimeSlot(atDate date: Date) -> Bool
    {
        guard let timeSlot = self.persistencyService.getLast() else { return true }
        
        let startDate = timeSlot.startTime
        var endDate = date
        
        guard endDate > startDate else
        {
            self.loggingService.log(withLogLevel: .error, message: "Trying to create a negative duration TimeSlot")
            return false
        }
        
        //TimeSlot is going for over one day, we should end it at midnight
        if startDate.ignoreTimeComponents() != endDate.ignoreTimeComponents()
        {
            self.loggingService.log(withLogLevel: .debug, message: "Early ending TimeSlot at midnight")
            endDate = startDate.tomorrow.ignoreTimeComponents()
        }
        
        let predicate = Predicate(parameter: "startTime", equals: timeSlot.startTime as AnyObject)
        let editFunction = { (timeSlot: TimeSlot) -> TimeSlot in
            
            timeSlot.endTime = endDate
            return timeSlot
        }
        
        timeSlot.endTime = endDate
        
        guard self.persistencyService.update(withPredicate: predicate, updateFunction: editFunction) else
        {
            self.loggingService.log(withLogLevel: .error, message: "Failed to end TimeSlot started at \(timeSlot.startTime) with category \(timeSlot.category)")
            
            return false
        }
        
        return true
    }
}
