import Foundation
import RxSwift

///ViewModel for the TimelineViewController.
class TimelineViewModel
{
    //MARK: Public Properties
    let date : Date
    let timeObservable : Observable<Void>
    var timelineItemsObservable : Observable<[TimelineItem]> { return self.timelineItems.asObservable() }

    var presentEditViewObservable : Observable<Void>
    {
        return self.appLifecycleService.startedOnNotificationObservable
            .filter({ [unowned self] in self.isCurrentDay })
    }

    //MARK: Private Properties
    private var isCurrentDay : Bool
    private let disposeBag = DisposeBag()
    
    private let timeService : TimeService
    private let timeSlotService : TimeSlotService
    private let editStateService : EditStateService
    private let appLifecycleService : AppLifecycleService
    private let loggingService : LoggingService
    
    private var activities : Variable<[Activity]> = Variable([])
    private var timelineItems : Variable<[TimelineItem]> = Variable([])
    
    //MARK: Initializers
    init(date completeDate: Date,
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
        self.date = completeDate.ignoreTimeComponents()
        
        isCurrentDay = timeService.now.ignoreTimeComponents() == date
        
        timeObservable = !isCurrentDay ? Observable.empty() : Observable<Int>.timer(1, period: 10, scheduler: MainScheduler.instance).mapTo(())
        
        let newTimeSlotForThisDate = !isCurrentDay ? Observable.empty() : timeSlotService
            .timeSlotCreatedObservable
            .filter(timeSlotBelongsToThisDate)
            .mapTo(())
        
        let updatedTimeSlotForThisDate = timeSlotService
            .timeSlotUpdatedObservable
            .filter(timeSlotBelongsToThisDate)
            .mapTo(())
        
        let movedToForeground = appLifecycleService
            .movedToForegroundObservable
            .mapTo(())
        
        let refreshObservable =
            Observable.of(newTimeSlotForThisDate, updatedTimeSlotForThisDate, movedToForeground)
                      .merge()
                      .startWith(()) // This is a hack I can't remove due to something funky with the view controllery lifecycle. We should fix this in the refactor
                
        refreshObservable
            .map(timeSlotsForToday)
            .map(toTimelineItems)
            .bindTo(timelineItems)
            .addDisposableTo(disposeBag)

    }
    
    //MARK: Public methods
    
    func notifyEditingBegan(point: CGPoint, index: Int)
    {
        editStateService
            .notifyEditingBegan(point: point,
                                timelineItem: timelineItems.value[index])
    }
    
    func calculateDuration(ofTimeSlot timeSlot: TimeSlot) -> TimeInterval
    {
        return timeSlotService.calculateDuration(ofTimeSlot: timeSlot)
    }
    
    
    //MARK: Private Methods
    private func timeSlotsForToday() -> [TimeSlot]
    {
        return timeSlotService.getTimeSlots(forDay: date)
    }
    
    
    private func toTimelineItems(fromTimeSlots timeSlots: [TimeSlot]) -> [TimelineItem]
    {
        let timelineItems = timeSlots
            .splitBy { $0.category }
            .reduce([TimelineItem](), { acc, groupedTimeSlots in
     
                if groupedTimeSlots.count > 1 && true // If it's expanded
                {
                    return acc + expandedTimelineItems(fromTimeSlots: groupedTimeSlots)
                }
                else
                {
                    return acc + [
                        TimelineItem(
                            timeSlots: groupedTimeSlots,
                            category: groupedTimeSlots.first!.category,
                            duration: groupedTimeSlots.map(calculateDuration).reduce(0, +),
                            shouldDisplayCategoryName: true,
                            isLastInPastDay: false,
                            isRunning: false,
                            hasCollapseButton: false)
                    ]
                }
            })
        
        // Add isLastInPastDay or isRunning to last timeslot of timeline
        guard let last = timelineItems.last else { return [] }
        return Array(timelineItems.dropLast()) + [last.withLastTimeSlotFlag(isCurrentDay: isCurrentDay)]
    }
    
    private func expandedTimelineItems(fromTimeSlots timeSlots: [TimeSlot]) -> [TimelineItem]
    {
        guard let first = timeSlots.first, let last = timeSlots.last, first.startTime != last.startTime else { return [] }
        let category = first.category
        
        return timeSlots.map {
            TimelineItem(
                withTimeSlots: [$0],
                category: category,
                duration: calculateDuration(ofTimeSlot: $0),
                shouldDisplayCategoryName: $0.startTime == first.startTime,
                hasCollapseButton: $0.startTime == last.startTime)
        }
    }
    
    private func timelineItem(fromTimeSlot timeSlot: TimeSlot) -> TimelineItem
    {
        return TimelineItem(
            withTimeSlots: [timeSlot],
            category: timeSlot.category,
            duration: calculateDuration(ofTimeSlot: timeSlot))
    }
    
    private func timeSlotBelongsToThisDate(_ timeSlot: TimeSlot) -> Bool
    {
        return timeSlot.startTime.ignoreTimeComponents() == date
    }
    
    private func isLastInPastDay(_ index: Int, count: Int) -> Bool
    {
        guard !isCurrentDay else { return false }
        
        let isLastEntry = count - 1 == index
        return isLastEntry
    }
}
