import Foundation
import XCTest
import RxSwift
import RxTest
import Nimble
@testable import teferi

class TimelineViewModelTests : XCTestCase
{
    private var disposeBag : DisposeBag = DisposeBag()
    private var viewModel : TimelineViewModel!
    
    private var timeService : MockTimeService!
    private var metricsService : MockMetricsService!
    private var locationService : MockLocationService!
    private var timeSlotService : MockTimeSlotService!
    private var editStateService : MockEditStateService!
    private var appLifecycleService : MockAppLifecycleService!
    private var loggingService : MockLoggingService!
    
    private var observer: TestableObserver<[TimelineItem]>!
    private var scheduler:TestScheduler!
    
    override func setUp()
    {
        disposeBag = DisposeBag()
        timeService = MockTimeService()
        metricsService = MockMetricsService()
        locationService = MockLocationService()
        editStateService = MockEditStateService()
        appLifecycleService = MockAppLifecycleService()
        timeSlotService = MockTimeSlotService(timeService: timeService,
                                                   locationService: locationService)
        loggingService = MockLoggingService()
        
        viewModel = TimelineViewModel(date: Date(),
                                           timeService: timeService,
                                           timeSlotService: timeSlotService,
                                           editStateService: editStateService,
                                           appLifecycleService: appLifecycleService,
                                           loggingService: loggingService)
        
        scheduler = TestScheduler(initialClock:0)
        observer = scheduler.createObserver([TimelineItem].self)
        viewModel.timelineItemsObservable
            .subscribe(observer)
            .addDisposableTo(disposeBag)
    }
    
    override func tearDown()
    {
        disposeBag = DisposeBag()
    }
    
    func testViewModelsForTheOlderDaysDoNotSubscribeForTimeSlotUpdates()
    {
        let newMockTimeSlotService = MockTimeSlotService(timeService: timeService,
                                                         locationService: locationService)
        _ = TimelineViewModel(date: Date().yesterday,
                              timeService: timeService,
                              timeSlotService: newMockTimeSlotService,
                              editStateService: editStateService,
                              appLifecycleService: appLifecycleService,
                              loggingService: loggingService)
        
        expect(newMockTimeSlotService.didSubscribe).to(beFalse())
    }
    
    func testTheNewlyAddedSlotHasNoEndTime()
    {
        addTimeSlot()
        
        let lastEvent = observer.events.last!
        let lastItem = lastEvent.value.element!.last!
        let timeSlot = lastItem.timeSlot
        
        expect(timeSlot.endTime).to(beNil())
    }
    
    func testTheAddNewSlotsMethodEndsThePreviousTimeSlot()
    {
        addTimeSlot()
        
        let lastEvent = observer.events.last!
        let firstItem = lastEvent.value.element!.first!
        let firstSlot = firstItem.timeSlot
        
        addTimeSlot()
        
        expect(firstSlot.endTime).toNot(beNil())
    }
    
    func testConsecutiveTimeSlotsShouldNotDisplayTheCategoryText()
    {
        addTimeSlot(minutesAfterNoon: 0)
        addTimeSlot(minutesAfterNoon: 3)
        
        let lastEvent = observer.events.last!
        let lastItem = lastEvent.value.element!.last!
        
        expect(lastItem.shouldDisplayCategoryName).to(beFalse())
    }
    
    func testViewModelNeverMergesUnknownTimeSlots()
    {
        addTimeSlot(minutesAfterNoon: 0, category: .unknown)
        addTimeSlot(minutesAfterNoon: 3, category: .unknown)
        
        let lastEvent = observer.events.last!
        let lastItem = lastEvent.value.element!.last!
        
        expect(lastItem.shouldDisplayCategoryName).to(beTrue())
    }
    
    func testUpdatingTheNthTimeSlotShouldRecalculateWhetherTheNPlus1thShouldDisplayTheCategoryTextOrNot()
    {
        addTimeSlot(minutesAfterNoon: 0)
        addTimeSlot(minutesAfterNoon: 3)
        addTimeSlot(minutesAfterNoon: 5)
        addTimeSlot(minutesAfterNoon: 8)
        
        var timelineItems = observer.events.last!.value.element!
        
        timeSlotService.update(timeSlot: timelineItems[2].timeSlot, withCategory: .leisure, setByUser: true)
        
        timelineItems = observer.events.last!.value.element!
        
        
        [ true, false, true, true ]
            .enumerated()
            .forEach { i, result in expect(timelineItems[i].shouldDisplayCategoryName).to(equal(result)) }
    }
    
    func testTheViewModelInitializesVerifyingTheShouldDisplayCategoryLogic()
    {
        addTimeSlot()
        
        let timeSlot = addTimeSlot()
        timeSlotService.update(timeSlot: timeSlot, withCategory: .leisure, setByUser: true)
        
        addTimeSlot()
        addTimeSlot()
        
        
        var timelineItems = observer.events.last!.value.element!

        [ true, true, true, false ]
            .enumerated()
            .forEach { i, result in expect(timelineItems[i].shouldDisplayCategoryName).to(equal(result)) }
    }
    
    func testViewModelForwardsUpdatesOnCategoriesForToday()
    {
        let ts = addTimeSlot(minutesAfterNoon: 0)
        addTimeSlot(minutesAfterNoon: 3)
        
        timeSlotService.update(timeSlot: ts, withCategory: .family, setByUser: true)
        
        let timelineItems = observer.events.last!.value.element!
        
        expect(self.observer.events.count).to(equal(4)) //3 events plus initial one
        expect(timelineItems[0].timeSlot.category).to(equal(Category.family))
    }
    
    func testViewModelForwardsUpdatesOnCategoriesForDaysBeforeToday()
    {
        let minutesOffset:TimeInterval = -3*24*60
        
        let ts = addTimeSlot(minutesAfterNoon: Int(0 + minutesOffset))
        addTimeSlot(minutesAfterNoon: Int(3 + minutesOffset))

        
        viewModel = TimelineViewModel(date: Date().addingTimeInterval(minutesOffset*60).ignoreTimeComponents(),
                                           timeService: timeService,
                                           timeSlotService: timeSlotService,
                                           editStateService: editStateService,
                                           appLifecycleService: appLifecycleService,
                                           loggingService: loggingService)
        
        observer = scheduler.createObserver([TimelineItem].self)
        viewModel.timelineItemsObservable
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        
        timeSlotService.update(timeSlot: ts, withCategory: .leisure, setByUser: true)
        
        let timelineItems = observer.events.last!.value.element!
        
        expect(self.observer.events.count).to(equal(2)) //initial one plus update one
        expect(timelineItems[0].timeSlot.category).to(equal(Category.leisure))
    }
    
    func testViewModelForwardsTimeSlotCreationForToday()
    {
        addTimeSlot(minutesAfterNoon: Int(20))
        expect(self.observer.events.count).to(equal(2)) //initial one plus new timeslot
    }
    
    func testViewModelDoesntForwardTimeSlotCreationForDaysBeforeToday()
    {
        let dateOffset:TimeInterval = -3*24*60*60
        
        viewModel = TimelineViewModel(date: Date().addingTimeInterval(dateOffset).ignoreTimeComponents(),
                                           timeService: timeService,
                                           timeSlotService: timeSlotService,
                                           editStateService: editStateService,
                                           appLifecycleService: appLifecycleService,
                                           loggingService: loggingService)
        
        observer = scheduler.createObserver([TimelineItem].self)
        viewModel.timelineItemsObservable
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        addTimeSlot(minutesAfterNoon: Int(20))
        expect(self.observer.events.count).to(equal(1)) //just initial one
    }
    
    func testNotifyEditingBeganGetsTheCorrectlyIndexedItem()
    {
        addTimeSlot(minutesAfterNoon: 0, category: .work)
        addTimeSlot(minutesAfterNoon: 3, category: .work)
        addTimeSlot(minutesAfterNoon: 5, category: .work)
        addTimeSlot(minutesAfterNoon: 8, category: .work)
        
        let observer:TestableObserver<(CGPoint, TimeSlot)> = scheduler.createObserver((CGPoint, TimeSlot).self)
        editStateService.beganEditingObservable
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        viewModel.notifyEditingBegan(point: .zero, index: 2)
        expect(observer.events.last!.value.element!.1.startTime).to(equal(Date.noon.addingTimeInterval(TimeInterval(5 * 60))))
    }
    
    func testOnlyTheLastOfMultipleTimeslotsShowsTheDuration()
    {
        addTimeSlot(minutesAfterNoon: 0, category: .work)
        addTimeSlot(minutesAfterNoon: 3, category: .work)
        addTimeSlot(minutesAfterNoon: 5, category: .work)
        addTimeSlot(minutesAfterNoon: 8, category: .work)
        
        var timelineItems = observer.events.last!.value.element!
        
        [ true, true, true, false ]
            .enumerated()
            .forEach { i, result in expect(timelineItems[i].durations.isEmpty).to(equal(result)) }
    }
    
    func testTheLastSlotContainsTheDurationsOfAllPreviousMergedSlots()
    {
        addTimeSlot(minutesAfterNoon: 0, category: .work)
        addTimeSlot(minutesAfterNoon: 3, category: .work)
        addTimeSlot(minutesAfterNoon: 5, category: .work)
        addTimeSlot(minutesAfterNoon: 8, category: .work)
        
        let timelineItems = observer.events.last!.value.element!
        
        ([ 3*60, 2*60, 3*60, -8*60 ] as [TimeInterval])
            .enumerated()
            .forEach { index, result in
                expect(timelineItems.last!.durations[index]).to(equal(result))
        }
    }
    
    func testFetchesTimeslotsWhenAppWakesUp()
    {
        let oldCount = observer.events.count
        appLifecycleService.publish(.movedToForeground(fromNotification: false))
        expect(self.observer.events.count).to(equal(oldCount + 1))
    }
    
    @discardableResult private func addTimeSlot(minutesAfterNoon: Int = 0) -> TimeSlot
    {
        return addTimeSlot(minutesAfterNoon: minutesAfterNoon, category: .work)
    }
    
    @discardableResult private func addTimeSlot(minutesAfterNoon: Int = 0, category : teferi.Category) -> TimeSlot
    {
        let noon = Date.noon
        
        return timeSlotService.addTimeSlot(withStartTime: noon.addingTimeInterval(TimeInterval(minutesAfterNoon * 60)),
                                                category: category,
                                                categoryWasSetByUser: false,
                                                tryUsingLatestLocation: false)!
    }
}
