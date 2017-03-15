import Foundation
import RxSwift
import CoreLocation
@testable import teferi

class MockTimeSlotService : TimeSlotService
{
    //MARK: Fields
    private let timeService : TimeService
    private let locationService : LocationService
    
    private let timeSlotCreatedSubject = PublishSubject<TimeSlot>()
    private let timeSlotUpdatedSubject = PublishSubject<TimeSlot>()
    
    //MARK: Properties
    private(set) var timeSlots = [TimeSlot]()
    private(set) var getLastTimeSlotWasCalled = false
    
    init(timeService: TimeService, locationService: LocationService)
    {
        self.timeService = timeService
        self.locationService = locationService
        
        self._timeSlotCreatedObservable = timeSlotCreatedSubject.asObservable()
        self.timeSlotUpdatedObservable = timeSlotUpdatedSubject.asObservable()
    }
    
    // MARK: Properties
    private let _timeSlotCreatedObservable : Observable<TimeSlot>
    var timeSlotCreatedObservable : Observable<TimeSlot>
    {
        self.didSubscribe = true
        return _timeSlotCreatedObservable
    }

    let timeSlotUpdatedObservable : Observable<TimeSlot>
    var didSubscribe = false
    
    // MARK: PersistencyService implementation
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
    
    func getLast() -> TimeSlot?
    {
        self.getLastTimeSlotWasCalled = true
        return timeSlots.last
    }
    
    func getTimeSlots(forDay day: Date) -> [TimeSlot]
    {
        let startDate = day.ignoreTimeComponents()
        let endDate = day.tomorrow.ignoreTimeComponents()
        
        return self.timeSlots.filter { t in t.startTime > startDate && t.startTime < endDate }
    }
    
    func getTimeSlots(sinceDaysAgo days: Int) -> [TimeSlot]
    {
        let today = self.timeService.now
        
        let startDate = today.add(days: -days).ignoreTimeComponents()
        let endDate = today.tomorrow.ignoreTimeComponents()
        
        return self.timeSlots.filter { t in t.startTime > startDate && t.startTime < endDate }
    }
    
    @discardableResult func addTimeSlot(withStartTime startTime: Date, category: teferi.Category, categoryWasSetByUser: Bool, tryUsingLatestLocation: Bool) -> TimeSlot?
    {
        let location : CLLocation? = tryUsingLatestLocation ? self.locationService.getLastKnownLocation() : nil
        return self.addTimeSlot(withStartTime: startTime, category: category, categoryWasSetByUser: categoryWasSetByUser, location:  location)
    }
    
    @discardableResult func addTimeSlot(withStartTime startTime: Date, category: teferi.Category, categoryWasSetByUser: Bool, location: CLLocation?) -> TimeSlot?
    {
        let timeSlot = TimeSlot(withStartTime: startTime, category: category, categoryWasSetByUser: categoryWasSetByUser, location: location)
        return self.tryAdd(timeSlot: timeSlot)
    }
    
    @discardableResult func addTimeSlot(withStartTime startTime: Date, smartGuess: SmartGuess, location: CLLocation) -> TimeSlot?
    {
        let timeSlot = TimeSlot(withStartTime: startTime, smartGuess: smartGuess, location: location)
        return self.tryAdd(timeSlot: timeSlot)
    }
    
    private func tryAdd(timeSlot: TimeSlot) -> TimeSlot
    {
        if let lastTimeSlot = timeSlots.last
        {
            lastTimeSlot.endTime = timeSlot.startTime
        }
        
        self.timeSlots.append(timeSlot)
        self.timeSlotCreatedSubject.on(.next(timeSlot))
        
        return timeSlot
    }
    
    @discardableResult func update(timeSlot: TimeSlot, withCategory category: teferi.Category, setByUser: Bool)
    {
        timeSlot.category = category
        timeSlot.categoryWasSetByUser = setByUser
        self.timeSlotUpdatedSubject.on(.next(timeSlot))
    }
}

class PagerMockTimeSlotService : MockTimeSlotService
{
    @discardableResult override func addTimeSlot(withStartTime startTime: Date, category: teferi.Category, categoryWasSetByUser: Bool, tryUsingLatestLocation: Bool) -> TimeSlot?
    {
        return nil
    }
    
    @discardableResult override func addTimeSlot(withStartTime startTime: Date, category: teferi.Category, categoryWasSetByUser: Bool, location: CLLocation?) -> TimeSlot?
    {
        return nil
    }
    
    @discardableResult override func addTimeSlot(withStartTime startTime: Date, smartGuess: SmartGuess, location: CLLocation) -> TimeSlot?
    {
        return nil
    }
}
