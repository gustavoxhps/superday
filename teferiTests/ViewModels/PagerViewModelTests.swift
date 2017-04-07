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
    
    func testWhenTheAppWakesFromANotificationItShouldShowEdit()
    {
        var editLastRow = false
        _ = self.viewModel.showEditOnLastObservable.subscribe({ _ in editLastRow = true })

        self.appLifecycleService.publish(.movedToForeground(fromNotification:true))
        
        expect(editLastRow).to(beTrue())
    }
}
