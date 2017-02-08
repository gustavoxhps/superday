import RxSwift
import XCTest
import Nimble
import CoreLocation
@testable import teferi

class MainViewModelTests : XCTestCase
{
    private var viewModel : MainViewModel!
    private var disposable : Disposable? = nil
    
    private var timeService : MockTimeService!
    private var metricsService : MockMetricsService!
    private var appStateService : MockAppStateService!
    private var feedbackService : MockFeedbackService!
    private var locationService : MockLocationService!
    private var settingsService : MockSettingsService!
    private var timeSlotService : MockTimeSlotService!
    private var editStateService : MockEditStateService!
    private var smartGuessService : MockSmartGuessService!
    private var selectedDateService : MockSelectedDateService!
    
    override func setUp()
    {
        self.timeService = MockTimeService()
        self.metricsService = MockMetricsService()
        self.appStateService = MockAppStateService()
        self.locationService = MockLocationService()
        self.settingsService = MockSettingsService()
        self.feedbackService = MockFeedbackService()
        self.editStateService = MockEditStateService()
        self.smartGuessService = MockSmartGuessService()
        self.selectedDateService = MockSelectedDateService()
        self.timeSlotService = MockTimeSlotService(timeService: self.timeService)
        
        self.viewModel = MainViewModel(timeService: self.timeService,
                                       metricsService: self.metricsService,
                                       timeSlotService: self.timeSlotService,
                                       locationService: self.locationService,
                                       editStateService: self.editStateService,
                                       smartGuessService: self.smartGuessService,
                                       selectedDateService: self.selectedDateService)
        
    }
    
    override func tearDown()
    {
        self.disposable?.dispose()
    }
    
    func testTheAddNewSlotsMethodAddsANewSlot()
    {
        var didAdd = false
        
        self.disposable = self.timeSlotService.timeSlotCreatedObservable.subscribe(onNext: { _ in didAdd = true })
        self.viewModel.addNewSlot(withCategory: .commute)
        
        expect(didAdd).to(beTrue())
    }
    
    func testTheAddNewSlotMethodCallsTheMetricsService()
    {
        self.viewModel.addNewSlot(withCategory: .commute)
        expect(self.metricsService.didLog(event: .timeSlotManualCreation)).to(beTrue())
    }
    
    func testTheUpdateMethodCallsTheMetricsService()
    {
        let timeSlot = self.createTimeSlot(withCategory: .work)
        self.timeSlotService.add(timeSlot: timeSlot)
        self.viewModel.updateTimeSlot(timeSlot, withCategory: .commute)
        
        expect(self.metricsService.didLog(event: .timeSlotEditing)).to(beTrue())
    }
    
    func testTheUpdateTimeSlotMethodChangesATimeSlotsCategory()
    {
        let timeSlot = self.createTimeSlot(withCategory: .work)
        self.timeSlotService.add(timeSlot: timeSlot)
        self.viewModel.updateTimeSlot(timeSlot, withCategory: .commute)
        
        expect(timeSlot.category).to(equal(Category.commute))
    }
    
    func testTheUpdateTimeSlotMethodEndsTheEditingProcess()
    {
        var editingEnded = false
        _ = self.editStateService
            .isEditingObservable
            .subscribe(onNext: { editingEnded = !$0 })
        
        let timeSlot = self.createTimeSlot(withCategory: .work)
        self.timeSlotService.add(timeSlot: timeSlot)
        self.viewModel.updateTimeSlot(timeSlot, withCategory: .commute)
        
        expect(editingEnded).to(beTrue())
    }
    
    func testSmartGuessIsAddedIfLocationServiceReturnsKnownLastLocationOnAddNewSlot()
    {
        self.locationService.setMockLocation(CLLocation(latitude:43.4211, longitude:4.7562))
        let previousCount = self.smartGuessService.smartGuesses.count
        
        self.viewModel.addNewSlot(withCategory: .food)
        
        expect(self.smartGuessService.smartGuesses.count).to(equal(previousCount + 1))
    }
    
    func testSmartGuessIsStrikedIfCategoryWasWrongOnUpdateTimeSlotMethod()
    {
        let location = CLLocation(latitude:43.4211, longitude:4.7562)
        let timeSlot = TimeSlot(withStartTime: Date(),
                                smartGuess: SmartGuess(withId: 0, category: .food, location: location, lastUsed: Date()),
                                location: location)
        
        self.timeSlotService.add(timeSlot: timeSlot)
        self.viewModel.updateTimeSlot(timeSlot, withCategory: .commute)
        
        expect(self.smartGuessService.smartGuesses.last?.errorCount).to(equal(1))
    }
    
    func testSmartGuessIsAddedIfUpdatingATimeSlotWithNoSmartGuesses()
    {
        let previousCount = self.smartGuessService.smartGuesses.count
        let timeSlot = TimeSlot(
            withStartTime: Date(timeIntervalSinceNow: -100),
            endTime: Date(),
            category: .food,
            location: CLLocation(latitude:43.4211, longitude:4.7562),
            categoryWasSetByUser: true)
        
        self.timeSlotService.add(timeSlot: timeSlot)
        self.viewModel.updateTimeSlot(timeSlot, withCategory: .commute)
        
        expect(self.smartGuessService.smartGuesses.count).to(equal(previousCount + 1))
    }
    
    func testTheUpdateMethodMarksTimeSlotAsSetByUser()
    {
        let location = CLLocation(latitude:43.4211, longitude:4.7562)
        let timeSlot = TimeSlot(withStartTime: Date(),
                                smartGuess: SmartGuess(withId: 0, category: .food, location: location, lastUsed: Date()),
                                location: location)
        
        self.timeSlotService.add(timeSlot: timeSlot)
        self.viewModel.updateTimeSlot(timeSlot, withCategory: .commute)
        
        expect(timeSlot.categoryWasSetByUser).to(beTrue())
    }
    
    private func createTimeSlot(withCategory category: teferi.Category) -> TimeSlot
    {
        return  TimeSlot(withStartTime: Date(), category: category, categoryWasSetByUser: false)
    }
}
