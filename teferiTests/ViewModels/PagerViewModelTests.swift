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
    private var appStateService : MockAppStateService!
    private var settingsService : MockSettingsService!
    private var editStateService : MockEditStateService!
    private var selectedDateService : MockSelectedDateService!
    
    override func setUp()
    {
        self.noon = Date().ignoreTimeComponents().addingTimeInterval(12 * 60 * 60)
        
        self.disposeBag = DisposeBag()
        self.timeService = MockTimeService()
        self.appStateService = MockAppStateService()
        self.settingsService = MockSettingsService()
        self.editStateService = MockEditStateService()
        self.selectedDateService = MockSelectedDateService()
        
        self.timeService.mockDate = self.noon
        
        self.viewModel = PagerViewModel(timeService: self.timeService,
                                        appStateService: self.appStateService,
                                        settingsService: self.settingsService,
                                        editStateService: self.editStateService,
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
                                        appStateService: self.appStateService,
                                        settingsService: self.settingsService,
                                        editStateService: self.editStateService,
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
        self.appStateService.currentAppState = .inactive
        
        expect(self.settingsService.lastInactiveDate).to(equal(expectedDate))
    }
    
    func testWhenTheAppBecomesActiveAndNeedsRefreshingTheLastInactiveDateIsErased()
    {
        self.settingsService.lastInactiveDate = Date()
        self.appStateService.currentAppState = .needsRefreshing
        
        expect(self.settingsService.lastInactiveDate).to(beNil())
    }
    
    func testWhenTheAppBecomesActiveAndNeedsRefreshingANewRefreshEventHappens()
    {
        var refreshEventHappened = false
        _ = self.viewModel.refreshObservable.subscribe({ _ in refreshEventHappened = true })
        
        self.appStateService.currentAppState = .needsRefreshing
        
        expect(refreshEventHappened).to(beTrue())
    }
    
    func testWhenTheAppBecomesActiveWithNoPriorInactiveDateNoEventShouldBePumped()
    {
        self.appStateService.currentAppState = .inactive
        self.settingsService.lastInactiveDate = nil
        
        var refreshEventHappened = false
        _ = self.viewModel.refreshObservable.subscribe({ _ in refreshEventHappened = true })
        
        self.appStateService.currentAppState = .active
        
        expect(refreshEventHappened).to(beFalse())
    }
    
    func testWhenTheAppBecomesActiveInTheSameDateNoEventShouldBePumped()
    {
        self.appStateService.currentAppState = .inactive
        
        var refreshEventHappened = false
        _ = self.viewModel.refreshObservable.subscribe({ _ in refreshEventHappened = true })
        
        self.appStateService.currentAppState = .active
        
        expect(refreshEventHappened).to(beFalse())
    }
    
    func testWhenTheAppBecomesActiveInTheNextDayANewEventIsPumped()
    {
        self.disposeBag = nil
        
        let today = self.timeService.now
        let tomorrow = self.timeService.now.tomorrow
        
        self.timeService.mockDate = today
        self.appStateService.currentAppState = .inactive
        
        var refreshEventHappened = false
        _ = self.viewModel.refreshObservable.subscribe({ _ in refreshEventHappened = true })
        
        self.timeService.mockDate = tomorrow
        self.appStateService.currentAppState = .active
        
        expect(refreshEventHappened).to(beTrue())
    }
    
    func testWhenTheAppBecomesActiveAndAnEventIsPumpedTheLastInactiveDateIsSetToNil()
    {
        self.appStateService.currentAppState = .inactive
        self.settingsService.lastInactiveDate = self.timeService.now
        self.timeService.mockDate = self.timeService.now.tomorrow
        self.appStateService.currentAppState = .active
        
        expect(self.settingsService.lastInactiveDate).to(beNil())
    }
}
