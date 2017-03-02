import RxSwift
import CoreLocation

///Service that creates and updates TimeSlots
protocol TimeSlotService
{
    var timeSlotCreatedObservable : Observable<TimeSlot> { get }
    var timeSlotUpdatedObservable : Observable<TimeSlot> { get }

    @discardableResult func addTimeSlot(withStartTime startTime: Date, category: Category, categoryWasSetByUser: Bool, tryUsingLatestLocation: Bool) -> TimeSlot?
    
    @discardableResult func addTimeSlot(withStartTime startTime: Date, category: Category, categoryWasSetByUser: Bool, location: CLLocation?) -> TimeSlot?
    
    @discardableResult func addTimeSlot(withStartTime startTime: Date, smartGuess: SmartGuess, location: CLLocation) -> TimeSlot?
    
    /**
     Gets TimeSlots for any given day.
     
     - Parameter day: The day used for filtering the TimeSlots.
     - Returns: The found TimeSlots for the day or an empty array if there are none.
     */
    func getTimeSlots(forDay day: Date) -> [TimeSlot]
    
    func getTimeSlots(sinceDaysAgo days: Int) -> [TimeSlot]
    
    /**
     Changes the category of an existing TimeSlot.
     
     - Parameter timeSlot: The TimeSlots to be updated.
     
     - Parameter category: The new category of the TimeSlot.
     
     - Parameter setByUser: Indicates if the user initiated the action that changed the TimeSlot.
     */
    func update(timeSlot: TimeSlot, withCategory category: Category, setByUser: Bool)
    
    /**
     Gets last registered TimeSlot.
     
     - Returns: The last saved TimeSlot.
     */
    func getLast() -> TimeSlot?
    
    /**
    Calculates the duration of a TimeSlot
     
     - Parameter timeSlot: The TimeSlot to use in the calculation
     - Returns: The duration of a timeslot
    */
    func calculateDuration(ofTimeSlot timeSlot: TimeSlot) -> TimeInterval
}
