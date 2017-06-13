import CoreData
import RxSwift
import Foundation
import CoreLocation

class DefaultTimeSlotService : TimeSlotService
{
    // MARK: Public Properties
    let timeSlotCreatedObservable : Observable<TimeSlot>
    let timeSlotUpdatedObservable : Observable<TimeSlot>
    
    // MARK: Private Properties
    private let timeService : TimeService
    private let loggingService : LoggingService
    private let locationService : LocationService
    private let persistencyService : BasePersistencyService<TimeSlot>
    
    private let timeSlotCreatedSubject = PublishSubject<TimeSlot>()
    private let timeSlotUpdatedSubject = PublishSubject<TimeSlot>()
    
    // MARK: Initializer
    init(timeService: TimeService,
         loggingService: LoggingService,
         locationService: LocationService,
         persistencyService: BasePersistencyService<TimeSlot>)
    {
        self.timeService = timeService
        self.loggingService = loggingService
        self.locationService = locationService
        self.persistencyService = persistencyService

        timeSlotCreatedObservable = timeSlotCreatedSubject.asObservable()
        timeSlotUpdatedObservable = timeSlotUpdatedSubject.asObservable()
    }

    // MARK: Public Methods
    @discardableResult func addTimeSlot(withStartTime startTime: Date, category: Category, categoryWasSetByUser: Bool, tryUsingLatestLocation: Bool) -> TimeSlot?
    {
        let location : CLLocation? = tryUsingLatestLocation ? locationService.getLastKnownLocation() : nil
        
        return addTimeSlot(withStartTime: startTime,
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
        
        return tryAdd(timeSlot: timeSlot)
    }
    
    @discardableResult func addTimeSlot(withStartTime startTime: Date, smartGuess: SmartGuess, location: CLLocation?) -> TimeSlot?
    {
        let timeSlot = TimeSlot(withStartTime: startTime,
                                smartGuess: smartGuess,
                                location: location)
        
        return tryAdd(timeSlot: timeSlot)
    }
    
    func getTimeSlots(forDay day: Date) -> [TimeSlot]
    {
        let startTime = day.ignoreTimeComponents() as NSDate
        let endTime = day.tomorrow.ignoreTimeComponents() as NSDate
        let predicate = Predicate(parameter: "startTime", rangesFromDate: startTime, toDate: endTime)
        
        let timeSlots = persistencyService.get(withPredicate: predicate)
        return timeSlots
    }
    
    func getTimeSlots(sinceDaysAgo days: Int) -> [TimeSlot]
    {
        let today = timeService.now.ignoreTimeComponents()
        
        let startTime = today.add(days: -days).ignoreTimeComponents() as NSDate
        let endTime = today.tomorrow.ignoreTimeComponents() as NSDate
        let predicate = Predicate(parameter: "startTime", rangesFromDate: startTime, toDate: endTime)
        
        let timeSlots = persistencyService.get(withPredicate: predicate)
        return timeSlots
    }
    
    func update(timeSlot: TimeSlot, withCategory category: Category, setByUser: Bool)
    {
        guard canChangeCategory(of: timeSlot, to: category, setByUser: setByUser) else { return }
        
        let predicate = Predicate(parameter: "startTime", equals: timeSlot.startTime as AnyObject)
        let editFunction = { (timeSlot: TimeSlot) -> (TimeSlot) in
            
            timeSlot.categoryWasSetByUser = setByUser
            timeSlot.category = category
            return timeSlot
        }
        
        if persistencyService.update(withPredicate: predicate, updateFunction: editFunction)
        {
            timeSlot.category = category
            timeSlotUpdatedSubject.on(.next(timeSlot))
        }
        else
        {
            loggingService.log(withLogLevel: .warning, message: "Error updating category of TimeSlot created on \(timeSlot.startTime) from \(timeSlot.category) to \(category)")
        }
    }
    
    func getLast() -> TimeSlot?
    {
        return persistencyService.getLast()
    }
    
    func calculateDuration(ofTimeSlot timeSlot: TimeSlot) -> TimeInterval
    {
        let endTime = getEndTime(ofTimeSlot: timeSlot)
        
        return endTime.timeIntervalSince(timeSlot.startTime)
    }
    
    // MARK: Private Methods
    private func tryAdd(timeSlot: TimeSlot) -> TimeSlot?
    {
        //The previous TimeSlot needs to be finished before a new one can start
        guard endPreviousTimeSlot(atDate: timeSlot.startTime) && persistencyService.create(timeSlot) else
        {
            loggingService.log(withLogLevel: .warning, message: "Failed to create new TimeSlot")
            return nil
        }
        
        loggingService.log(withLogLevel: .info, message: "New TimeSlot with category \"\(timeSlot.category)\" created")
        
        timeSlotCreatedSubject.on(.next(timeSlot))
        
        return timeSlot
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
        
        loggingService.log(withLogLevel: .warning, message: "Tried automatically updating category of TimeSlot which was set by user")
        return false
    }
    
    private func getEndTime(ofTimeSlot timeSlot: TimeSlot) -> Date
    {
        if let endTime = timeSlot.endTime { return endTime}
        
        let date = timeService.now
        let timeEntryLimit = timeSlot.startTime.tomorrow.ignoreTimeComponents()
        let timeEntryLastedOverOneDay = date > timeEntryLimit
        
        //TimeSlots can't go past midnight
        let endTime = timeEntryLastedOverOneDay ? timeEntryLimit : date
        return endTime
    }
    
    private func endPreviousTimeSlot(atDate date: Date) -> Bool
    {
        guard let timeSlot = persistencyService.getLast() else { return true }
        
        let startDate = timeSlot.startTime
        var endDate = date
        
        guard endDate > startDate else
        {
            loggingService.log(withLogLevel: .warning, message: "Trying to create a negative duration TimeSlot")
            return false
        }
        
        //TimeSlot is going for over one day, we should end it at midnight
        if startDate.ignoreTimeComponents() != endDate.ignoreTimeComponents()
        {
            loggingService.log(withLogLevel: .info, message: "Early ending TimeSlot at midnight")
            endDate = startDate.tomorrow.ignoreTimeComponents()
        }
        
        let predicate = Predicate(parameter: "startTime", equals: timeSlot.startTime as AnyObject)
        let editFunction = { (timeSlot: TimeSlot) -> TimeSlot in
            
            timeSlot.endTime = endDate
            return timeSlot
        }
        
        timeSlot.endTime = endDate
        
        guard persistencyService.update(withPredicate: predicate, updateFunction: editFunction) else
        {
            loggingService.log(withLogLevel: .warning, message: "Failed to end TimeSlot started at \(timeSlot.startTime) with category \(timeSlot.category)")
            return false
        }
        
        return true
    }
}
