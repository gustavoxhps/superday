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
        noon = Date().ignoreTimeComponents().addingTimeInterval(12 * 60 * 60)
        
        disposeBag = DisposeBag()
        timeService = MockTimeService()
        settingsService = MockSettingsService()
        editStateService = MockEditStateService()
        selectedDateService = MockSelectedDateService()
        appLifecycleService = MockAppLifecycleService()
        
        timeService.mockDate = noon
        
        viewModel = PagerViewModel(timeService: timeService,
                                        settingsService: settingsService,
                                        editStateService: editStateService,
                                        appLifecycleService: appLifecycleService,
                                        selectedDateService: selectedDateService)
        
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
        timeService.mockDate = noon
        
        viewModel = PagerViewModel(timeService: timeService,
                                        settingsService: settingsService,
                                        editStateService: editStateService,
                                        appLifecycleService: appLifecycleService,
                                        selectedDateService: selectedDateService)
        
        var value = false
        disposable = viewModel.dateObservable.subscribe(onNext: { _ in value = true })
        
        let otherDate = noon.addingTimeInterval(60)
        viewModel.currentlySelectedDate = otherDate
        
        expect(value).to(beFalse())
    }
    
    func testTheViewModelCanNotAllowScrollsToDatesBeforeTheAppInstall()
    {
        let appInstallDate = Date().yesterday
        settingsService.setInstallDate(appInstallDate)
        
        let theDayBeforeInstallDate = appInstallDate.yesterday
        
        expect(self.viewModel.canScroll(toDate: theDayBeforeInstallDate)).to(beFalse())
    }
    
    func testTheViewModelAllowsScrollsToDatesAfterTheAppWasInstalledAndBeforeTheCurrentDate()
    {
        let appInstallDate = Date().add(days: -3)
        settingsService.setInstallDate(appInstallDate)
        
        let theDayAfterInstallDate = appInstallDate.tomorrow
        
        expect(self.viewModel.canScroll(toDate: theDayAfterInstallDate)).to(beTrue())
    }
    
    func testWhenTheAppWakesFromANotificationItShouldShowEdit()
    {
        var editLastRow = false
        _ = viewModel.showEditOnLastObservable.subscribe({ _ in editLastRow = true })

        appLifecycleService.publish(.movedToForeground(fromNotification:true))
        
        expect(editLastRow).to(beTrue())
    }
}
