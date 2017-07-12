import Foundation
import RxSwift
import CoreLocation
@testable import teferi

class SimpleMockTimeSlotService : TimeSlotService
{
    var newTimeSlotToReturn: TimeSlot? = nil
    var timeSlotsToReturn: [TimeSlot]? = nil
    var durationToReturn: TimeInterval = 0
    
    private(set) var dateAsked:Date? = nil
    
    var timeSlotCreatedObservable : Observable<TimeSlot> = Observable<TimeSlot>.empty()
    var timeSlotUpdatedObservable : Observable<TimeSlot> = Observable<TimeSlot>.empty()
    
    @discardableResult func addTimeSlot(withStartTime startTime: Date, category: teferi.Category, categoryWasSetByUser: Bool, tryUsingLatestLocation: Bool) -> TimeSlot?
    {
        return newTimeSlotToReturn
    }
    
    @discardableResult func addTimeSlot(withStartTime startTime: Date, category: teferi.Category, categoryWasSetByUser: Bool, location: CLLocation?) -> TimeSlot?
    {
        return newTimeSlotToReturn
    }
    
    @discardableResult func addTimeSlot(withStartTime startTime: Date, smartGuess: SmartGuess, location: CLLocation?) -> TimeSlot?
    {
        return newTimeSlotToReturn
    }
    
    func getTimeSlots(forDay day: Date) -> [TimeSlot]
    {
        dateAsked = day
        return timeSlotsToReturn ?? []
    }
    
    func getTimeSlots(sinceDaysAgo days: Int) -> [TimeSlot]
    {
        return timeSlotsToReturn ?? []
    }
    
    func getTimeSlots(betweenDate firstDate: Date, andDate secondDate: Date) -> [TimeSlot]
    {
        return timeSlotsToReturn ?? []
    }

    func update(timeSlot: TimeSlot, withCategory category: teferi.Category)
    {
        
    }
    
    func getLast() -> TimeSlot?
    {
        return timeSlotsToReturn?.last
    }
    
    func calculateDuration(ofTimeSlot timeSlot: TimeSlot) -> TimeInterval
    {
        return durationToReturn
    }
}
