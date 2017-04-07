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
        self.disposeBag = DisposeBag()
        self.timeService = MockTimeService()
        self.metricsService = MockMetricsService()
        self.locationService = MockLocationService()
        self.editStateService = MockEditStateService()
        self.appLifecycleService = MockAppLifecycleService()
        self.timeSlotService = MockTimeSlotService(timeService: self.timeService,
                                                   locationService: self.locationService)
        self.loggingService = MockLoggingService()
        
        self.viewModel = TimelineViewModel(date: Date(),
                                           timeService: self.timeService,
                                           timeSlotService: self.timeSlotService,
                                           editStateService: self.editStateService,
                                           appLifecycleService: self.appLifecycleService,
                                           loggingService: self.loggingService)
        
        scheduler = TestScheduler(initialClock:0)
        observer = scheduler.createObserver([TimelineItem].self)
        viewModel.timelineItemsObservable
            .subscribe(observer)
            .addDisposableTo(disposeBag)
    }
    
    override func tearDown()
    {
        self.disposeBag = DisposeBag()
    }
    
    func testViewModelsForTheOlderDaysDoNotSubscribeForTimeSlotUpdates()
    {
        let newMockTimeSlotService = MockTimeSlotService(timeService: self.timeService,
                                                         locationService: self.locationService)
        _ = TimelineViewModel(date: Date().yesterday,
                              timeService: self.timeService,
                              timeSlotService: newMockTimeSlotService,
                              editStateService: self.editStateService,
                              appLifecycleService: self.appLifecycleService,
                              loggingService: self.loggingService)
        
        expect(newMockTimeSlotService.didSubscribe).to(beFalse())
    }
    
    func testTheNewlyAddedSlotHasNoEndTime()
    {
        self.addTimeSlot()
        
        let lastEvent = observer.events.last!
        let lastItem = lastEvent.value.element!.last!
        let timeSlot = lastItem.timeSlot
        
        expect(timeSlot.endTime).to(beNil())
    }
    
    func testTheAddNewSlotsMethodEndsThePreviousTimeSlot()
    {
        self.addTimeSlot()
        
        let lastEvent = observer.events.last!
        let firstItem = lastEvent.value.element!.first!
        let firstSlot = firstItem.timeSlot
        
        self.addTimeSlot()
        
        expect(firstSlot.endTime).toNot(beNil())
    }
    
    func testConsecutiveTimeSlotsShouldNotDisplayTheCategoryText()
    {
        self.addTimeSlot(minutesAfterNoon: 0)
        self.addTimeSlot(minutesAfterNoon: 3)
        
        let lastEvent = observer.events.last!
        let lastItem = lastEvent.value.element!.last!
        
        expect(lastItem.shouldDisplayCategoryName).to(beFalse())
    }
    
    func testViewModelNeverMergesUnknownTimeSlots()
    {
        self.addTimeSlot(minutesAfterNoon: 0, category: .unknown)
        self.addTimeSlot(minutesAfterNoon: 3, category: .unknown)
        
        let lastEvent = observer.events.last!
        let lastItem = lastEvent.value.element!.last!
        
        expect(lastItem.shouldDisplayCategoryName).to(beTrue())
    }
    
    func testUpdatingTheNthTimeSlotShouldRecalculateWhetherTheNPlus1thShouldDisplayTheCategoryTextOrNot()
    {
        self.addTimeSlot(minutesAfterNoon: 0)
        self.addTimeSlot(minutesAfterNoon: 3)
        self.addTimeSlot(minutesAfterNoon: 5)
        self.addTimeSlot(minutesAfterNoon: 8)
        
        var timelineItems = observer.events.last!.value.element!
        
        self.timeSlotService.update(timeSlot: timelineItems[2].timeSlot, withCategory: .leisure, setByUser: true)
        
        timelineItems = observer.events.last!.value.element!
        
        
        [ true, false, true, true ]
            .enumerated()
            .forEach { i, result in expect(timelineItems[i].shouldDisplayCategoryName).to(equal(result)) }
    }
    
    func testTheViewModelInitializesVerifyingTheShouldDisplayCategoryLogic()
    {
        self.addTimeSlot()
        
        let timeSlot = self.addTimeSlot()
        self.timeSlotService.update(timeSlot: timeSlot, withCategory: .leisure, setByUser: true)
        
        self.addTimeSlot()
        self.addTimeSlot()
        
        
        var timelineItems = observer.events.last!.value.element!

        [ true, true, true, false ]
            .enumerated()
            .forEach { i, result in expect(timelineItems[i].shouldDisplayCategoryName).to(equal(result)) }
    }
    
    func testViewModelForwardsUpdatesOnCategoriesForToday()
    {
        let ts = self.addTimeSlot(minutesAfterNoon: 0)
        self.addTimeSlot(minutesAfterNoon: 3)
        
        self.timeSlotService.update(timeSlot: ts, withCategory: .family, setByUser: true)
        
        let timelineItems = observer.events.last!.value.element!
        
        expect(self.observer.events.count).to(equal(4)) //3 events plus initial one
        expect(timelineItems[0].timeSlot.category).to(equal(Category.family))
    }
    
    func testViewModelForwardsUpdatesOnCategoriesForDaysBeforeToday()
    {
        let minutesOffset:TimeInterval = -3*24*60
        
        let ts = self.addTimeSlot(minutesAfterNoon: Int(0 + minutesOffset))
        self.addTimeSlot(minutesAfterNoon: Int(3 + minutesOffset))

        
        self.viewModel = TimelineViewModel(date: Date().addingTimeInterval(minutesOffset*60).ignoreTimeComponents(),
                                           timeService: self.timeService,
                                           timeSlotService: self.timeSlotService,
                                           editStateService: self.editStateService,
                                           appLifecycleService: self.appLifecycleService,
                                           loggingService: self.loggingService)
        
        observer = scheduler.createObserver([TimelineItem].self)
        viewModel.timelineItemsObservable
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        
        self.timeSlotService.update(timeSlot: ts, withCategory: .leisure, setByUser: true)
        
        let timelineItems = observer.events.last!.value.element!
        
        expect(self.observer.events.count).to(equal(2)) //initial one plus update one
        expect(timelineItems[0].timeSlot.category).to(equal(Category.leisure))
    }
    
    func testViewModelForwardsTimeSlotCreationForToday()
    {
        self.addTimeSlot(minutesAfterNoon: Int(20))
        expect(self.observer.events.count).to(equal(2)) //initial one plus new timeslot
    }
    
    func testViewModelDoesntForwardTimeSlotCreationForDaysBeforeToday()
    {
        let dateOffset:TimeInterval = -3*24*60*60
        
        self.viewModel = TimelineViewModel(date: Date().addingTimeInterval(dateOffset).ignoreTimeComponents(),
                                           timeService: self.timeService,
                                           timeSlotService: self.timeSlotService,
                                           editStateService: self.editStateService,
                                           appLifecycleService: self.appLifecycleService,
                                           loggingService: self.loggingService)
        
        observer = scheduler.createObserver([TimelineItem].self)
        viewModel.timelineItemsObservable
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        self.addTimeSlot(minutesAfterNoon: Int(20))
        expect(self.observer.events.count).to(equal(1)) //just initial one
    }
    
    @discardableResult private func addTimeSlot(minutesAfterNoon: Int = 0) -> TimeSlot
    {
        return self.addTimeSlot(minutesAfterNoon: minutesAfterNoon, category: .work)
    }
    
    @discardableResult private func addTimeSlot(minutesAfterNoon: Int = 0, category : teferi.Category) -> TimeSlot
    {
        let noon = Date().ignoreTimeComponents().addingTimeInterval(12 * 60 * 60)
        
        return self.timeSlotService.addTimeSlot(withStartTime: noon.addingTimeInterval(TimeInterval(minutesAfterNoon * 60)),
                                                category: category,
                                                categoryWasSetByUser: false,
                                                tryUsingLatestLocation: false)!
    }
}
