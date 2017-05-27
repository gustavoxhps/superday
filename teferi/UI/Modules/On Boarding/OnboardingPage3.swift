import UIKit
import RxSwift
import CoreLocation

class OnboardingPage3 : OnboardingPage, CLLocationManagerDelegate
{
    private var locationManager: CLLocationManager!
    private var disposeBag : DisposeBag? = DisposeBag()
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder, nextButtonText: nil)
    }
    
    override func startAnimations()
    {
        disposeBag = disposeBag ?? DisposeBag()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        appLifecycleService
            .movedToForegroundObservable
            .subscribe(onNext: onMovedToForeground)
            .addDisposableTo(disposeBag!)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        if status == .authorizedAlways || status == .denied
        {
            if status == .authorizedAlways {
                settingsService.setUserGaveLocationPermission()
            }

            finish()
        }
    }
    
    override func finish()
    {
        locationManager.delegate = nil
        onboardingPageViewController.goToNextPage(forceNext: true)
        disposeBag = nil
    }
    
    func onMovedToForeground()
    {
        if onboardingPageViewController.isCurrent(page: self)
            && !settingsService.hasLocationPermission
        {
            locationManager.requestAlwaysAuthorization()
        }
    }
}
