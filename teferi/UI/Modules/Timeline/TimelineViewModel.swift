import Foundation
import RxSwift

///ViewModel for the TimelineViewController.
class TimelineViewModel
{
    //MARK: Fields
    private var isCurrentDay : Bool
    private let disposeBag = DisposeBag()
    
    private let timeService : TimeService
    private let timeSlotService : TimeSlotService
    private let editStateService : EditStateService
    private let appLifecycleService : AppLifecycleService
    private let loggingService : LoggingService
    
    private var timelineItems:Variable<[TimelineItem]> = Variable([])
    
    //MARK: Initializers
    init(date: Date,
         timeService: TimeService,
         timeSlotService: TimeSlotService,
         editStateService: EditStateService,
         appLifecycleService: AppLifecycleService,
         loggingService: LoggingService)
    {
        self.timeService = timeService
        self.timeSlotService = timeSlotService
        self.editStateService = editStateService
        self.appLifecycleService = appLifecycleService
        self.loggingService = loggingService

        self.isCurrentDay = self.timeService.now.ignoreTimeComponents() == date.ignoreTimeComponents()
        self.date = date.ignoreTimeComponents()
        
        self.timeObservable = !isCurrentDay ? Observable.empty() : Observable<Int>.timer(1, period: 10, scheduler: MainScheduler.instance).mapTo(())
        
        let newTimeSlotForThisDate = !isCurrentDay ? Observable.empty() : self.timeSlotService
            .timeSlotCreatedObservable
            .filter(self.timeSlotBelongsToThisDate)
            .mapTo(())
        
        let updatedTimeSlotForThisDate = self.timeSlotService
            .timeSlotUpdatedObservable
            .filter(self.timeSlotBelongsToThisDate)
            .mapTo(())
        
        let movedToForeground = self.appLifecycleService
            .movedToForegroundObservable
            .mapTo(())
        
        let refreshObservable = Observable.of(newTimeSlotForThisDate, updatedTimeSlotForThisDate, movedToForeground).merge()
        
        refreshObservable
            .startWith(()) // This is a hack I can't remove due to something funky with the view controllery lifecycle. We should fix this in the refactor
            .map(timeSlotsForToday)
            .map(toTimelineItems)
            .bindTo(self.timelineItems)
            .addDisposableTo(disposeBag)

    }
    
    //MARK: Properties
    let date : Date
    let timeObservable : Observable<Void>
    var timelineItemsObservable : Observable<[TimelineItem]> { return self.timelineItems.asObservable() }
    
    var presentEditViewObservable : Observable<Void>
    {
        return self.appLifecycleService.startedOnNotificationObservable
            .filter({ [unowned self] in self.isCurrentDay })            
    }
    
    //MARK: Public methods
    
    func notifyEditingBegan(point: CGPoint, index: Int)
    {
        self.editStateService
            .notifyEditingBegan(point: point,
                                timeSlot: self.timelineItems.value[index].timeSlot)
    }
    
    func calculateDuration(ofTimeSlot timeSlot: TimeSlot) -> TimeInterval
    {
        return self.timeSlotService.calculateDuration(ofTimeSlot: timeSlot)
    }
    
    
    //MARK: Private Methods
    private func timeSlotsForToday() -> [TimeSlot]
    {
        return self.timeSlotService.getTimeSlots(forDay: self.date)
    }
    
    
    private func toTimelineItems(fromTimeSlots timeSlots: [TimeSlot]) -> [TimelineItem]
    {
        let count = timeSlots.count
        
        return timeSlots
            .enumerated()
            .reduce([TimelineItem]()) { accumulated, enumerated in
                
                let timeSlot = enumerated.element
                let n = enumerated.offset
                let isLastInPastDay = self.isLastInPastDay(n, count: count)
                
                if isLastInPastDay && timeSlot.endTime == nil {
                    loggingService.log(withLogLevel: .error, message: "Timeslot error: Can't be last in past day and still running")
                }
                
                if timeSlot.category != .unknown,
                    let last = accumulated.last,
                    last.timeSlot.category == timeSlot.category
                {
                    return accumulated.dropLast() + [
                        last.withoutDurations(),
                        TimelineItem(timeSlot: timeSlot,
                                     durations: last.durations + [self.timeSlotService.calculateDuration(ofTimeSlot: timeSlot)],
                                     lastInPastDay: isLastInPastDay,
                                     shouldDisplayCategoryName: false)
                    ]
                }
                
                return accumulated + [
                    TimelineItem(timeSlot: timeSlot,
                                 durations: [self.timeSlotService.calculateDuration(ofTimeSlot: timeSlot)],
                                 lastInPastDay: isLastInPastDay,
                                 shouldDisplayCategoryName: true)
                ]
        }
    }
    
    private func timeSlotBelongsToThisDate(_ timeSlot: TimeSlot) -> Bool
    {
        return timeSlot.startTime.ignoreTimeComponents() == self.date
    }
    
    private func isLastInPastDay(_ index: Int, count: Int) -> Bool
    {
        guard !self.isCurrentDay else { return false }
        
        let isLastEntry = count - 1 == index
        return isLastEntry
    }
}
