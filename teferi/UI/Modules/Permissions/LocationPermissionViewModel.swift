import RxSwift
import Foundation

class LocationPermissionViewModel : PermissionViewModel
{
    // MARK: Public Properties
    var remindMeLater : Bool
    {
        return isFirstTimeUser
    }

    var titleText : String?
    {
        return self.isFirstTimeUser ? self.titleFirstUse : self.title
    }
    
    var descriptionText : String
    {
        return self.isFirstTimeUser ? self.disabledDescriptionFirstUse : self.disabledDescription
    }
    
    var enableButtonTitle : String
    {
        return L10n.locationEnableButtonTitle
    }
    
    var image : UIImage?
    {
        return nil
    }
    
    var permissionGivenObservable : Observable<Void>
    {
        return self.appLifecycleService
            .movedToForegroundObservable
            .map { [unowned self] in
                return self.settingsService.hasLocationPermission
            }
            .filter{ $0 }
            .mapTo(())
    }
    
    private(set) lazy var hideOverlayObservable : Observable<Void> =
    {
        return self.appLifecycleService.movedToForegroundObservable
            .map(self.overlayVisibilityState)
            .filter{ !$0 }
            .mapTo(())
            .debug()
    }()
    
    // MARK: Private Properties
    private let title = L10n.locationDisabledTitle
    private let titleFirstUse = L10n.locationDisabledTitleFirstUse
    private let disabledDescription = L10n.locationDisabledDescription
    private let disabledDescriptionFirstUse = L10n.locationDisabledDescriptionFirstUse
    
    private let timeService : TimeService
    private let settingsService : SettingsService
    private let appLifecycleService : AppLifecycleService
    
    private let disposeBag = DisposeBag()
    
    private var isFirstTimeUser : Bool { return !self.settingsService.userEverGaveLocationPermission }
    
    // MARK: Initializers
    init(timeService: TimeService,
         settingsService: SettingsService,
         appLifecycleService : AppLifecycleService)
    {
        self.timeService = timeService
        self.settingsService = settingsService
        self.appLifecycleService = appLifecycleService
    }
    
    // MARK: Public Methods
    
    func getUserPermission()
    {
        let url = URL(string: UIApplicationOpenSettingsURLString)!
        UIApplication.shared.openURL(url)
    }
    
    func permissionGiven()
    {
        if settingsService.userEverGaveLocationPermission {
            settingsService.setLastAskedForLocationPermission(timeService.now)
        } else {
            settingsService.setUserGaveLocationPermission()
        }
    }
    
    func permissionDeferred()
    {
        settingsService.setLastAskedForLocationPermission(timeService.now)
    }
    
    // MARK: Private Methods
        
    private func overlayVisibilityState() -> Bool
    {
        return !settingsService.hasLocationPermission
    }
}
