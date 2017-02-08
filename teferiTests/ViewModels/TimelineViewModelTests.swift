import Foundation
import XCTest
import RxSwift
import Nimble
@testable import teferi

class TimelineViewModelTests : XCTestCase
{
    private var disposeBag : DisposeBag? = nil
    private var viewModel : TimelineViewModel!
    
    private var timeService : TimeService!
    private var metricsService : MockMetricsService!
    private var appStateService : MockAppStateService!
    private var timeSlotService : MockTimeSlotService!
    private var editStateService : MockEditStateService!
    
    override func setUp()
    {
        self.disposeBag = DisposeBag()
        self.timeService = MockTimeService()
        self.metricsService = MockMetricsService()
        self.appStateService = MockAppStateService()
        self.editStateService = MockEditStateService()
        self.timeSlotService = MockTimeSlotService(timeService: self.timeService)
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
        let newMockTimeSlotService = MockTimeSlotService(timeService: self.timeService)
        _ = TimelineViewModel(date: Date().yesterday,
                              timeService: self.timeService,
                              appStateService: self.appStateService,
                              timeSlotService: newMockTimeSlotService,
                              editStateService: self.editStateService)
        
        expect(newMockTimeSlotService.didSubscribe).to(beFalse())
    }
    
    func testTheNewlyAddedSlotHasNoEndTime()
    {
        let timeSlot = self.createTimeSlot()
        self.timeSlotService.add(timeSlot: timeSlot)
        let lastSlot = viewModel.timelineItems.last!.timeSlot
        
        expect(lastSlot.endTime).to(beNil())
    }
    
    func testTheAddNewSlotsMethodEndsThePreviousTimeSlot()
    {
        let timeSlot = self.createTimeSlot()
        self.timeSlotService.add(timeSlot: timeSlot)
        let firstSlot = viewModel.timelineItems.first!.timeSlot
        
        let otherTimeSlot = self.createTimeSlot()
        self.timeSlotService.add(timeSlot: otherTimeSlot)
        
        expect(firstSlot.endTime).toNot(beNil())
    }
    
    func testConsecutiveTimeSlotsShouldNotDisplayTheCategoryText()
    {
        self.timeSlotService.add(timeSlot: self.createTimeSlot(minutesAfterNoon: 0))
        self.timeSlotService.add(timeSlot: self.createTimeSlot(minutesAfterNoon: 3))
        
        expect(self.viewModel.timelineItems.last!.shouldDisplayCategoryName).to(beFalse())
    }
    
    func testUpdatingTheNthTimeSlotShouldRecalculateWhetherTheNPlus1thShouldDisplayTheCategoryTextOrNot()
    {
        self.viewModel.refreshScreenObservable.subscribe(onNext: { _ in () }).addDisposableTo(self.disposeBag!)
        
        self.timeSlotService.add(timeSlot: self.createTimeSlot(minutesAfterNoon: 0))
        self.timeSlotService.add(timeSlot: self.createTimeSlot(minutesAfterNoon: 3))
        self.timeSlotService.add(timeSlot: self.createTimeSlot(minutesAfterNoon: 5))
        self.timeSlotService.add(timeSlot: self.createTimeSlot(minutesAfterNoon: 8))
        
        self.timeSlotService.update(timeSlot: self.viewModel.timelineItems[2].timeSlot, withCategory: .leisure, setByUser: true)
        
        [ true, false, true, true ]
            .enumerated()
            .forEach { i, result in expect(self.viewModel.timelineItems[i].shouldDisplayCategoryName).to(equal(result)) }
    }
    
    func testTheViewModelInitializesVerifyingTheShouldDisplayCategoryLogic()
    {
        self.timeSlotService = MockTimeSlotService(timeService: self.timeService)
        self.timeSlotService.add(timeSlot: self.createTimeSlot())
        
        let timeSlot = self.createTimeSlot()
        self.timeSlotService.add(timeSlot: timeSlot)
        self.timeSlotService.update(timeSlot: timeSlot, withCategory: .leisure, setByUser: true)
        
        self.timeSlotService.add(timeSlot: self.createTimeSlot())
        self.timeSlotService.add(timeSlot: self.createTimeSlot())
     
        self.viewModel = TimelineViewModel(date: Date(),
                                           timeService: self.timeService,
                                           appStateService: self.appStateService,
                                           timeSlotService: self.timeSlotService,
                                           editStateService: self.editStateService)
        
        [ true, true, true, false ]
            .enumerated()
            .forEach { i, result in expect(self.viewModel.timelineItems[i].shouldDisplayCategoryName).to(equal(result)) }
    }
    
    private func createTimeSlot(minutesAfterNoon: Int = 0) -> TimeSlot
    {
        let noon = Date().ignoreTimeComponents().addingTimeInterval(12 * 60 * 60)
        return TimeSlot(withStartTime: noon.addingTimeInterval(TimeInterval(minutesAfterNoon * 60)) 	, category: .work, categoryWasSetByUser: false)
    }
}
