import RxSwift
import Foundation

class HealthKitPermissionViewModel : PermissionViewModel
{
    // MARK: Fields
    private let timeService : TimeService
    private let settingsService : SettingsService
    private let appLifecycleService : AppLifecycleService
    private let healthKitService : HealthKitService
    
    private let visibilitySubject = PublishSubject<Bool>()
    
    private let disposeBag = DisposeBag()
    
    // MARK: Initializers
    init(timeService: TimeService,
         settingsService: SettingsService,
         appLifecycleService : AppLifecycleService,
         healthKitService : HealthKitService)
    {
        self.timeService = timeService
        self.settingsService = settingsService
        self.appLifecycleService = appLifecycleService
        self.healthKitService = healthKitService
    }
    
    // MARK: Properties
    
    var remindMeLater : Bool
    {
        return false
    }
    
    var titleText : String?
    {
        return nil
    }
    
    var descriptionText : String
    {
        return L10n.healthKitDisabledDescription
    }
    
    var enableButtonTitle : String
    {
        return L10n.healthKitEnableButtonTitle
    }
    
    var image : UIImage?
    {
        return Asset.healthKitUserAccessImage.image
    }
    
    var permissionGivenObservable : Observable<Void>
    {
        return Observable.create({ observer in
            observer.on(.next())
            observer.on(.completed)
            return Disposables.create()
        })
        .shareReplayLatestWhileConnected()
    }
    
    private(set) lazy var hideOverlayObservable : Observable<Void> =
    {
        let appStateObservable = self.appLifecycleService
            .movedToForegroundObservable
            .startWith(())
            .map(self.overlayVisibilityState)
            .shareReplayLatestWhileConnected()
        
        let visibiltyObservable = self.visibilitySubject
            .asObservable()
            .startWith(self.overlayVisibilityState())
        
        return Observable.of(appStateObservable, visibiltyObservable)
            .merge()
            .filter{ !$0 }
            .mapTo(())
    }()
    
    func getUserPermission()
    {
        healthKitService.startHealthKitTracking()
    }
    
    func permissionGiven()
    {
        settingsService.setUserGaveHealthKitPermission()
        self.visibilitySubject.on(.next(false))
    }
    
    func permissionDeferred() {}
    
    private func overlayVisibilityState() -> Bool
    {
        return !settingsService.hasHealthKitPermission
    }
}
