import Foundation
import XCTest
import RxSwift
import Nimble
@testable import teferi

class TimelineViewModelTests : XCTestCase
{
    private var disposeBag : DisposeBag? = nil
    private var viewModel : TimelineViewModel!
    
    private var timeService : MockTimeService!
    private var metricsService : MockMetricsService!
    private var appStateService : MockAppStateService!
    private var locationService : MockLocationService!
    private var timeSlotService : MockTimeSlotService!
    private var editStateService : MockEditStateService!
    
    override func setUp()
    {
        self.disposeBag = DisposeBag()
        self.timeService = MockTimeService()
        self.metricsService = MockMetricsService()
        self.appStateService = MockAppStateService()
        self.locationService = MockLocationService()
        self.editStateService = MockEditStateService()
        self.timeSlotService = MockTimeSlotService(timeService: self.timeService,
                                                   locationService: self.locationService)
        self.viewModel = TimelineViewModel(date: Date(),
                                           timeService: self.timeService,
                                           appStateService: self.appStateService,
                                           timeSlotService: self.timeSlotService,
                                           editStateService: self.editStateService)
    }
    
    override func tearDown()
    {
        self.disposeBag = nil
    }
    
    func testViewModelsForTheOlderDaysDoNotSubscribeForTimeSlotUpdates()
    {
        let newMockTimeSlotService = MockTimeSlotService(timeService: self.timeService,
                                                         locationService: self.locationService)
        _ = TimelineViewModel(date: Date().yesterday,
                              timeService: self.timeService,
                              appStateService: self.appStateService,
                              timeSlotService: newMockTimeSlotService,
                              editStateService: self.editStateService)
        
        expect(newMockTimeSlotService.didSubscribe).to(beFalse())
    }
    
    func testTheNewlyAddedSlotHasNoEndTime()
    {
        self.addTimeSlot()
        let lastSlot = viewModel.timelineItems.last!.timeSlot
        
        expect(lastSlot.endTime).to(beNil())
    }
    
    func testTheAddNewSlotsMethodEndsThePreviousTimeSlot()
    {
        self.addTimeSlot()
        let firstSlot = viewModel.timelineItems.first!.timeSlot
        
        self.addTimeSlot()
        
        expect(firstSlot.endTime).toNot(beNil())
    }
    
    func testConsecutiveTimeSlotsShouldNotDisplayTheCategoryText()
    {
        self.addTimeSlot(minutesAfterNoon: 0)
        self.addTimeSlot(minutesAfterNoon: 3)
        
        expect(self.viewModel.timelineItems.last!.shouldDisplayCategoryName).to(beFalse())
    }
    
    func testViewModelNeverMergesUnknownTimeSlots()
    {
        self.addTimeSlot(minutesAfterNoon: 0, category: .unknown)
        self.addTimeSlot(minutesAfterNoon: 3, category: .unknown)
        
        expect(self.viewModel.timelineItems.last!.shouldDisplayCategoryName).to(beTrue())
    }
    
    func testUpdatingTheNthTimeSlotShouldRecalculateWhetherTheNPlus1thShouldDisplayTheCategoryTextOrNot()
    {
        self.viewModel.refreshScreenObservable.subscribe(onNext: { _ in () }).addDisposableTo(self.disposeBag!)
        
        self.addTimeSlot(minutesAfterNoon: 0)
        self.addTimeSlot(minutesAfterNoon: 3)
        self.addTimeSlot(minutesAfterNoon: 5)
        self.addTimeSlot(minutesAfterNoon: 8)
        
        self.timeSlotService.update(timeSlot: self.viewModel.timelineItems[2].timeSlot, withCategory: .leisure, setByUser: true)
        
        [ true, false, true, true ]
            .enumerated()
            .forEach { i, result in expect(self.viewModel.timelineItems[i].shouldDisplayCategoryName).to(equal(result)) }
    }
    
    func testTheViewModelInitializesVerifyingTheShouldDisplayCategoryLogic()
    {
        self.timeSlotService = MockTimeSlotService(timeService: self.timeService,
                                                   locationService: self.locationService)
        self.addTimeSlot()
        
        let timeSlot = self.addTimeSlot()
        self.timeSlotService.update(timeSlot: timeSlot, withCategory: .leisure, setByUser: true)
        
        self.addTimeSlot()
        self.addTimeSlot()
        
        self.viewModel = TimelineViewModel(date: Date(),
                                           timeService: self.timeService,
                                           appStateService: self.appStateService,
                                           timeSlotService: self.timeSlotService,
                                           editStateService: self.editStateService)
        
        [ true, true, true, false ]
            .enumerated()
            .forEach { i, result in expect(self.viewModel.timelineItems[i].shouldDisplayCategoryName).to(equal(result)) }
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
