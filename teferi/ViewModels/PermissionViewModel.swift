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
    var isVisible = false
    
    var isFirstTimeUser : Bool { return self.settingsService.canIgnoreLocationPermission }
    
    var titleText : String
    {
        return self.isFirstTimeUser ? self.titleFirstUse : self.title
    }
    
    var descriptionText : String
    {
        return self.isFirstTimeUser ? self.disabledDescriptionFirstUse : self.disabledDescription
    }
    
    private var shouldShowLocationPermissionOverlay : Bool
    {
        if self.settingsService.hasLocationPermission { return false }
        
        //If user doesn't have permissions and we never showed the overlay, do it
        guard let lastRequestedDate = self.settingsService.lastAskedForLocationPermission else { return true }
        
        let minimumRequestDate = lastRequestedDate.add(days: 1)
        
        //If we previously showed the overlay, we must only do it again after 24 hours
        return minimumRequestDate < self.timeService.now
    }
    
    private lazy var overlayStateObservable : Observable<Bool> =
    {
        return self.appLifecycleService
                   .lifecycleEventObservable
                   .filter(self.movedToForeground)
                   .map(self.toOverlayState)
                   .distinctUntilChanged { $0 != self.isVisible }
    }()
    
    private(set) lazy var showOverlayObservable : Observable<Void> =
    {
        return self.overlayStateObservable
                   .filter{ $0 }
                   .map { _ in () }
    }()
    
    private(set) lazy var hideOverlayObservable : Observable<Void> =
    {
        return self.overlayStateObservable
                   .filter{ !$0 }
                   .map { _ in self.settingsService.setAllowedLocationPermission() }
    }()
    
    func setLastAskedForLocationPermission() { self.settingsService.setLastAskedForLocationPermission(self.timeService.now) }
    
    private func movedToForeground(_ event: LifecycleEvent) -> Bool
    {
        return event == .movedToForeground
    }
    
    private func toOverlayState(_ ignore: LifecycleEvent) -> Bool
    {
        if self.settingsService.hasLocationPermission { return false }
        
        //If user doesn't have permissions and we never showed the overlay, do it
        guard let lastRequestedDate = self.settingsService.lastAskedForLocationPermission else { return true }
        
        let minimumRequestDate = lastRequestedDate.add(days: 1)
        
        //If we previously showed the overlay, we must only do it again after 24 hours
        return minimumRequestDate < self.timeService.now
    }
}
