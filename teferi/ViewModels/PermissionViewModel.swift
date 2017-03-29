import RxSwift
import Foundation

class PermissionViewModel
{
    // MARK: Fields
    private let title = L10n.locationDisabledTitle
    private let titleFirstUse = L10n.locationDisabledTitleFirstUse
    private let disabledDescription = L10n.locationDisabledDescription
    private let disabledDescriptionFirstUse = L10n.locationDisabledDescriptionFirstUse
    
    private let timeService : TimeService
    private let settingsService : SettingsService
    private let appLifecycleService : AppLifecycleService
    
    private let disposeBag = DisposeBag()
    
    // MARK: Initializers
    init(timeService: TimeService,
         settingsService: SettingsService,
         appLifecycleService : AppLifecycleService)
    {
        self.timeService = timeService
        self.settingsService = settingsService
        self.appLifecycleService = appLifecycleService
    }
    
    // MARK: Properties
    var isFirstTimeUser : Bool { return !self.settingsService.userEverGaveLocationPermission }
    
    var titleText : String
    {
        return self.isFirstTimeUser ? self.titleFirstUse : self.title
    }
    
    var descriptionText : String
    {
        return self.isFirstTimeUser ? self.disabledDescriptionFirstUse : self.disabledDescription
    }
    
    var permissionGivenObservable : Observable<Void> {
        return self.appLifecycleService
            .movedToForegroundObservable
            .map { [unowned self] in
                return self.settingsService.hasLocationPermission
            }
            .filter{ $0 }
            .mapTo(())
    }
    
    private lazy var overlayVisibilityStateObservable : Observable<Bool> =
    {
        return self.appLifecycleService
            .movedToForegroundObservable
            .startWith(())
            .map(self.overlayVisibilityState)
            .shareReplayLatestWhileConnected()
    }()
    
    private(set) lazy var showOverlayObservable : Observable<Void> =
    {
        return self.overlayVisibilityStateObservable
                   .filter{ $0 }
                   .mapTo(())
    }()
    
    private(set) lazy var hideOverlayObservable : Observable<Void> =
    {
        return self.overlayVisibilityStateObservable
                   .filter{ !$0 }
                   .mapTo(())
    }()
    
    func permissionGiven()
    {
        if self.settingsService.userEverGaveLocationPermission {
            self.settingsService.setLastAskedForLocationPermission(self.timeService.now)
        } else {
            self.settingsService.setUserGaveLocationPermission()
        }
    }
    
    func permissionDeferred()
    {
        self.settingsService.setLastAskedForLocationPermission(self.timeService.now)
    }
        
    private func overlayVisibilityState() -> Bool
    {
        if self.settingsService.hasLocationPermission { return false }
        
        //If user doesn't have permissions and we never showed the overlay, do it
        guard let lastRequestedDate = self.settingsService.lastAskedForLocationPermission else { return true }
        
        let minimumRequestDate = lastRequestedDate.add(days: 1)
        
        //If we previously showed the overlay, we must only do it again after 24 hours
        return minimumRequestDate < self.timeService.now
    }
}
