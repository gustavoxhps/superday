import RxSwift
import XCTest
import Nimble
@testable import teferi

class HealthKitPermissionViewModelTests : XCTestCase
{
    private var viewModel : PermissionViewModel!
    private var disposable : Disposable? = nil
    
    private var timeService : MockTimeService!
    private var settingsService : MockSettingsService!
    private var appLifecycleService : MockAppLifecycleService!
    private var healthKitService : MockHealthKitService!
    
    override func setUp()
    {
        self.timeService = MockTimeService()
        self.settingsService = MockSettingsService()
        self.appLifecycleService = MockAppLifecycleService()
        self.healthKitService = MockHealthKitService()
        
        self.viewModel = HealthKitPermissionViewModel(timeService: self.timeService,
                                                      settingsService: self.settingsService,
                                                      appLifecycleService: self.appLifecycleService,
                                                      healthKitService: self.healthKitService)
    }
    
    override func tearDown()
    {
        self.disposable?.dispose()
    }
    
    func testThePermissionStateShouldNotBeShownIfTheUserHasAlreadyAuthorized()
    {
        self.settingsService.hasHealthKitPermission = true
        
        var wouldShow = false
        self.disposable = self.viewModel
            .showOverlayObservable
            .subscribe(onNext:  { wouldShow = true })
        
        expect(wouldShow).to(beFalse())
    }
    
    func testThePermissionStateShouldBeShownIfItWasNotShownForTheDurationSpecifiedInConstant()
    {
        self.timeService.mockDate = Date().addingTimeInterval(Constants.timeToWaitBeforeShowingHealthKitPermissions)
        self.settingsService.hasHealthKitPermission = false
        
        var wouldShow = false
        self.disposable = self.viewModel
            .showOverlayObservable
            .subscribe(onNext: { _ in wouldShow = true })
        
        self.appLifecycleService.publish(.movedToForeground(fromNotification:false))
        
        expect(wouldShow).to(beTrue())
    }
    
    func testThePermissionStateShouldBeNotShownIfItWasNotShownBeforTheDurationSpecifiedInConstant()
    {
        self.timeService.mockDate = Date().addingTimeInterval(Constants.timeToWaitBeforeShowingHealthKitPermissions - 15*60)
        self.settingsService.hasHealthKitPermission = false
        
        var wouldShow = false
        self.disposable = self.viewModel
            .showOverlayObservable
            .subscribe(onNext: { _ in wouldShow = true })
        
        self.appLifecycleService.publish(.movedToForeground(fromNotification:false))
        
        expect(wouldShow).to(beFalse())
    }
    
    func testPermissionShouldShowNonBlockingOverlayIfUserAlreadyGavePermission()
    {
        self.settingsService.hasLocationPermission = false
        self.settingsService.lastAskedForLocationPermission = nil
        
        self.viewModel.permissionGiven()
        
        self.appLifecycleService.publish(.movedToForeground(fromNotification:false))
        
        expect(self.viewModel.remindMeLater).to(beFalse())
    }
}
