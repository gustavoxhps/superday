import Foundation
import RxSwift

///ViewModel for the TimelineViewController.
class TimelineViewModel
{
    //MARK: Fields
    private let isCurrentDay : Bool
    private let disposeBag = DisposeBag()
    
    private let timeService : TimeService
    private let appStateService : AppStateService
    private let timeSlotService : TimeSlotService
    private let editStateService : EditStateService
    
    //MARK: Initializers
    init(date: Date,
         timeService: TimeService,
         appStateService: AppStateService,
         timeSlotService: TimeSlotService,
         editStateService: EditStateService)
    {
        self.timeService = timeService
        self.appStateService = appStateService
        self.timeSlotService = timeSlotService
        self.editStateService = editStateService
        
        self.isCurrentDay = self.timeService.now.ignoreTimeComponents() == date.ignoreTimeComponents()
        self.date = date.ignoreTimeComponents()
        
        self.timeObservable =
            self.isCurrentDay ?
                Observable<Int>.timer(0, period: 10, scheduler: MainScheduler.instance) :
            Observable.empty()
    }
    
    func notifyEditingBegan(point: CGPoint, index: Int)
    {
        self.editStateService
            .notifyEditingBegan(point: point,
                                timeSlot: self.timelineItems[index].timeSlot)
    }
    
    //MARK: Properties
    let date : Date
    let timeObservable : Observable<Int>
    
    var currentDay : Date { return self.timeService.now }
    var isEditingObservable : Observable<Bool> { return self.editStateService.isEditingObservable }
    
    private(set) lazy var timeSlotCreatedObservable : Observable<Int> =
    {
        let createObservable =
            self.timeSlotService
                .timeSlotCreatedObservable
                .filter(self.timeSlotBelongsToThisDate)
                .map(self.toTimelineItemIndex)
        
        return createObservable
    }()
    
    private(set) lazy var refreshScreenObservable : Observable<Void> =
    {
        let updateObservable =
            self.timeSlotService
                .timeSlotUpdatedObservable
                .filter(self.timeSlotBelongsToThisDate)
                .map(self.refreshTimeSlotsFromService)
        
        let stateObservable =
            self.isCurrentDay ?
                Observable.empty() :
                self.appStateService
                    .appStateObservable
                    .filter(self.appIsActive)
                    .map(self.refreshTimeSlotsFromService)
        
        return Observable.of(stateObservable, updateObservable).merge()
    }()
			
    private(set) lazy var timelineItems : [TimelineItem] =
    {
        let timeSlots = self.timeSlotService.getTimeSlots(forDay: self.date)
        let timelineItems = self.getTimelineItems(fromTimeSlots: timeSlots)
    
        //Creates an empty TimeSlot if there are no TimeSlots for today
        if self.isCurrentDay && timelineItems.count == 0
        {
            self.timeSlotService.add(timeSlot: TimeSlot(withStartTime: self.timeService.now, categoryWasSetByUser: false))
        }
    
        return timelineItems
    }()
    
    //MARK: Methods
    func calculateDuration(ofTimeSlot timeSlot: TimeSlot) -> TimeInterval
    {
        return self.timeSlotService.calculateDuration(ofTimeSlot: timeSlot)
    }

    private func appIsActive(_ appState: AppState) -> Bool { return appState == .active }

    private func timeSlotBelongsToThisDate(_ timeSlot: TimeSlot) -> Bool { return timeSlot.startTime.ignoreTimeComponents() == self.date }
    
    private func refreshTimeSlotsFromService(_ ignore: Any) -> Void
    {
        let timeSlots = self.timeSlotService.getTimeSlots(forDay: self.date)
        self.timelineItems = self.getTimelineItems(fromTimeSlots: timeSlots)
    }
    
    private func toTimelineItemIndex(_ timeSlot: TimeSlot) -> Int
    {
        let previousIndex = self.timelineItems.count - 1
        
        let previousTimelineItem = self.timelineItems.safeGetElement(at: previousIndex)
        let shouldDisplayCategory = TimelineViewModel.shouldDisplay(currentTimeSlot: timeSlot,
                                                                    otherTimeSlot: previousTimelineItem?.timeSlot)
        
        var durations = [ self.timeSlotService.calculateDuration(ofTimeSlot: timeSlot) ]
        
        if let slotToRecalculate = previousTimelineItem?.timeSlot, let previousDurations = previousTimelineItem?.durations
        {
            slotToRecalculate.endTime = self.timeService.now
            
            let shouldDisplayDuration = TimelineViewModel.shouldDisplay(currentTimeSlot: slotToRecalculate,
                                                                        otherTimeSlot: timeSlot)
            
            let recalculatedDuration : [ TimeInterval ]
            if shouldDisplayDuration
            {
                recalculatedDuration = previousDurations
            }
            else
            {
                recalculatedDuration = []
                durations = (previousDurations + durations)
            }
            
            let otherTimeSlot = self.timelineItems.safeGetElement(at: previousIndex - 1)?.timeSlot
            
            let shouldDisplayPreviousCategory = TimelineViewModel.shouldDisplay(currentTimeSlot: slotToRecalculate,
                                                                                otherTimeSlot: otherTimeSlot)
            
            self.timelineItems[previousIndex] = TimelineItem(timeSlot: slotToRecalculate,
                                                             durations: recalculatedDuration,
                                                             lastInPastDay: false,
                                                             shouldDisplayCategoryName: shouldDisplayPreviousCategory)
        }
        
        
        let timelineItem = TimelineItem(timeSlot: timeSlot,
                                        durations: durations,
                                        lastInPastDay: false,
                                        shouldDisplayCategoryName: shouldDisplayCategory)
        
        self.timelineItems.append(timelineItem)
        
        return self.timelineItems.count - 1
    }
    
    private func isLastInPastDay(_ index: Int, count: Int) -> Bool
    {
        guard !self.isCurrentDay else { return false }
        
        let isLastEntry = count - 1 == index
        return isLastEntry
    }
    
    private func getTimelineItems(fromTimeSlots timeSlots: [TimeSlot]) -> [TimelineItem]
    {
        let count = timeSlots.count
        var timelineItems = [TimelineItem]()
        var previousTimeSlot : TimeSlot? = nil
        var accumulatedDurations = [ TimeInterval ]()
        
        for (index, timeSlot) in timeSlots.enumerated()
        {
            let nextIndex = index + 1
            let nextTimeSlot = timeSlots.safeGetElement(at: nextIndex)
            
            let shouldDisplayCategory = TimelineViewModel.shouldDisplay(currentTimeSlot: timeSlot,
                                                           otherTimeSlot: previousTimeSlot)
            
            let shouldDisplayDuration = TimelineViewModel.shouldDisplay(currentTimeSlot: timeSlot,
                                                           otherTimeSlot: nextTimeSlot)

            
            accumulatedDurations.append(self.timeSlotService.calculateDuration(ofTimeSlot: timeSlot))
            let durations : [ TimeInterval ]
            
            if shouldDisplayDuration
            {
                durations = accumulatedDurations
                accumulatedDurations = []
            }
            else
            {
                durations = []
            }
            
            timelineItems.append(TimelineItem(timeSlot: timeSlot,
                                              durations: durations,
                                              lastInPastDay: self.isLastInPastDay(index, count: count),
                                              shouldDisplayCategoryName: shouldDisplayCategory))
            
            previousTimeSlot = timeSlot
        }
        
        return timelineItems
    }
    
    private static func shouldDisplay(currentTimeSlot: TimeSlot, otherTimeSlot: TimeSlot?) -> Bool
    {
        guard let previous = otherTimeSlot else { return true }
        
        return previous.category != currentTimeSlot.category
    }
}
