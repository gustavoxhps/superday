import XCTest
import Nimble
import RxSwift
@testable import teferi

class PagerViewModelTests : XCTestCase
{
    //MARK: Fields
    private var noon : Date!
    
    private var disposeBag : DisposeBag!
    private var viewModel : PagerViewModel!
    
    private var disposable : Disposable!
    private var timeService : MockTimeService!
    private var settingsService : MockSettingsService!
    private var editStateService : MockEditStateService!
    private var appLifecycleService : MockAppLifecycleService!
    private var selectedDateService : MockSelectedDateService!
    
    override func setUp()
    {
        self.noon = Date().ignoreTimeComponents().addingTimeInterval(12 * 60 * 60)
        
        self.disposeBag = DisposeBag()
        self.timeService = MockTimeService()
        self.settingsService = MockSettingsService()
        self.editStateService = MockEditStateService()
        self.selectedDateService = MockSelectedDateService()
        self.appLifecycleService = MockAppLifecycleService()
        
        self.timeService.mockDate = self.noon
        
        self.viewModel = PagerViewModel(timeService: self.timeService,
                                        settingsService: self.settingsService,
                                        editStateService: self.editStateService,
                                        appLifecycleService: self.appLifecycleService,
                                        selectedDateService: self.selectedDateService)
        
        self.viewModel.refreshObservable.subscribe().addDisposableTo(disposeBag)
    }
    
    override func tearDown()
    {
        disposable?.dispose()
        disposable = nil
    }
    
    func testTheViewModelCanNotAllowScrollsAfterTheCurrentDate()
    {
        let tomorrow = Date().tomorrow
        
        expect(self.viewModel.canScroll(toDate: tomorrow)).to(beFalse())
    }
    
    func testTheCurrentDateObservableDoesNotPumpEventsForSameDayDates()
    {
        let noon = Date().ignoreTimeComponents().addingTimeInterval(12 * 60 * 60)
        self.timeService.mockDate = noon
        
        self.viewModel = PagerViewModel(timeService: self.timeService,
                                        settingsService: self.settingsService,
                                        editStateService: self.editStateService,
                                        appLifecycleService: self.appLifecycleService,
                                        selectedDateService: self.selectedDateService)
        
        var value = false
        self.disposable = self.viewModel.dateObservable.subscribe(onNext: { _ in value = true })
        
        let otherDate = noon.addingTimeInterval(60)
        viewModel.currentlySelectedDate = otherDate
        
        expect(value).to(beFalse())
    }
    
    func testTheViewModelCanNotAllowScrollsToDatesBeforeTheAppInstall()
    {
        let appInstallDate = Date().yesterday
        self.settingsService.setInstallDate(appInstallDate)
        
        let theDayBeforeInstallDate = appInstallDate.yesterday
        
        expect(self.viewModel.canScroll(toDate: theDayBeforeInstallDate)).to(beFalse())
    }
    
    func testTheViewModelAllowsScrollsToDatesAfterTheAppWasInstalledAndBeforeTheCurrentDate()
    {
        let appInstallDate = Date().add(days: -3)
        self.settingsService.setInstallDate(appInstallDate)
        
        let theDayAfterInstallDate = appInstallDate.tomorrow
        
        expect(self.viewModel.canScroll(toDate: theDayAfterInstallDate)).to(beTrue())
    }
    
    func testWhenTheAppBecomesInactiveTheLastInactiveDateShouldBeSet()
    {
        let expectedDate = self.noon
        self.timeService.mockDate = expectedDate
        
        self.settingsService.lastInactiveDate = nil
        self.appLifecycleService.publish(.movedToBackground)
        
        expect(self.settingsService.lastInactiveDate).to(equal(expectedDate))
    }
    
    func testWhenTheAppBecomesActiveAndNeedsRefreshingTheLastInactiveDateIsErased()
    {
        self.settingsService.lastInactiveDate = Date()
        self.appLifecycleService.publish(.invalidatedUiState)
        
        expect(self.settingsService.lastInactiveDate).to(beNil())
    }
    
    func testWhenTheAppBecomesActiveAndNeedsRefreshingANewRefreshEventHappens()
    {
        var refreshEventHappened = false
        _ = self.viewModel.refreshObservable.subscribe({ _ in refreshEventHappened = true })
        
        self.appLifecycleService.publish(.invalidatedUiState)
        
        expect(refreshEventHappened).to(beTrue())
    }
    
    func testWhenTheAppBecomesActiveWithNoPriorInactiveDateNoEventShouldBePumped()
    {
        self.appLifecycleService.publish(.movedToBackground)
        self.settingsService.lastInactiveDate = nil
        
        var refreshEventHappened = false
        _ = self.viewModel.refreshObservable.subscribe({ _ in refreshEventHappened = true })
        
        self.appLifecycleService.publish(.movedToForeground)
        
        expect(refreshEventHappened).to(beFalse())
    }
    
    func testWhenTheAppBecomesActiveInTheSameDateNoEventShouldBePumped()
    {
        self.appLifecycleService.publish(.movedToBackground)
        
        var refreshEventHappened = false
        _ = self.viewModel.refreshObservable.subscribe({ _ in refreshEventHappened = true })
        
        self.appLifecycleService.publish(.movedToForeground)
        
        expect(refreshEventHappened).to(beFalse())
    }
    
    func testWhenTheAppBecomesActiveInTheNextDayANewEventIsPumped()
    {
        self.disposeBag = nil
        
        let today = self.timeService.now
        let tomorrow = self.timeService.now.tomorrow
        
        self.timeService.mockDate = today
        self.appLifecycleService.publish(.movedToBackground)
        
        var refreshEventHappened = false
        _ = self.viewModel.refreshObservable.subscribe({ _ in refreshEventHappened = true })
        
        self.timeService.mockDate = tomorrow
        self.appLifecycleService.publish(.movedToForeground)

        expect(refreshEventHappened).toEventually(beTrue())
    }

    func testWhenTheAppBecomesActiveAndAnEventIsPumpedTheLastInactiveDateIsSetToNil()
    {
        self.appLifecycleService.publish(.movedToBackground)
        self.settingsService.lastInactiveDate = self.timeService.now
        self.timeService.mockDate = self.timeService.now.tomorrow
        self.appLifecycleService.publish(.movedToForeground)
        
        expect(self.settingsService.lastInactiveDate).to(beNil())
    }
}
