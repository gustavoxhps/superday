import RxSwift
import XCTest
import Nimble
@testable import teferi

class PermissionViewModelTests : XCTestCase
{
    private var viewModel : PermissionViewModel!
    private var disposable : Disposable? = nil
    
    private var timeService : MockTimeService!
    private var appStateService : MockAppStateService!
    private var settingsService : MockSettingsService!
    
    override func setUp()
    {
        self.timeService = MockTimeService()
        self.appStateService = MockAppStateService()
        self.settingsService = MockSettingsService()
        
        self.viewModel = PermissionViewModel(timeService: self.timeService,
                                             appStateService: self.appStateService,
                                             settingsService: self.settingsService)
    }
    
    override func tearDown()
    {
        self.disposable?.dispose()
    }
    
    func testThePermissionStateShouldNotBeShownIfTheUserHasAlreadyAuthorized()
    {
        self.settingsService.hasLocationPermission = true
        
        var wouldShow = false
        self.disposable = self.viewModel
            .showOverlayObservable
            .subscribe(onNext:  { wouldShow = true })
        
        expect(wouldShow).to(beFalse())
    }
    
    func testIfThePermissionOverlayWasNeverShownItNeedsToBeShown()
    {
        self.settingsService.hasLocationPermission = false
        self.settingsService.lastAskedForLocationPermission = nil
        
        var wouldShow = false
        self.disposable = self.viewModel
            .showOverlayObservable
            .subscribe(onNext: { _ in wouldShow = true })
        
        expect(wouldShow).to(beTrue())
    }
    
    func testThePermissionStateShouldBeShownIfItWasNotShownForOver24Hours()
    {
        self.settingsService.hasLocationPermission = false
        self.settingsService.lastAskedForLocationPermission = Date().add(days: -2)
        
        var wouldShow = false
        self.disposable = self.viewModel
            .showOverlayObservable
            .subscribe(onNext: { _ in wouldShow = true })
        
        expect(wouldShow).to(beTrue())
    }
    
    func testThePermissionStateShouldNotBeShownIfItWasLastShownInTheLast24Hours()
    {
        self.settingsService.hasLocationPermission = false
        self.settingsService.lastAskedForLocationPermission = Date().ignoreTimeComponents()
        
        var wouldShow = false
        self.disposable = self.viewModel
            .showOverlayObservable
            .subscribe(onNext: { _ in wouldShow = true })
        
        expect(wouldShow).to(beFalse())
    }
}
