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
    
    func testPermissionShouldShowNonBlockingOverlayIfUserAlreadyGavePermission()
    {
        self.settingsService.hasLocationPermission = false
        self.settingsService.lastAskedForLocationPermission = nil
        
        self.viewModel.permissionGiven()
        
        self.appLifecycleService.publish(.movedToForeground(fromNotification:false))
        
        expect(self.viewModel.remindMeLater).to(beFalse())
    }
}
