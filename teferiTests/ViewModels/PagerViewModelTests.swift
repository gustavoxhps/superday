import XCTest
import Nimble
import RxSwift
@testable import teferi

class PagerViewModelTests : XCTestCase
{
    //MARK: Fields
    private var viewModel : PagerViewModel!
    
    private var disposable : Disposable? = nil
    private var timeService : MockTimeService!
    private var appStateService : AppStateService!
    private var settingsService : SettingsService!
    private var editStateService : EditStateService!
    private var selectedDateService : SelectedDateService!
    
    override func setUp()
    {
        self.timeService = MockTimeService()
        self.appStateService = MockAppStateService()
        self.settingsService = MockSettingsService()
        self.editStateService = MockEditStateService()
        self.selectedDateService = MockSelectedDateService()
        
        self.viewModel = PagerViewModel(timeService: self.timeService,
                                        appStateService: self.appStateService,
                                        settingsService: self.settingsService,
                                        editStateService: self.editStateService,
                                        selectedDateService: self.selectedDateService)
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
}
