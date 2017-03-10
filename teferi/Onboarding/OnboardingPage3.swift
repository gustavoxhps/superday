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
        self.disposeBag = self.disposeBag ?? DisposeBag()
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        
        self.appLifecycleService
            .lifecycleEventObservable
            .subscribe(onNext: self.onLifecycleEvent)
            .addDisposableTo(self.disposeBag!)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        if status == .authorizedAlways || status == .denied
        {
            if status == .authorizedAlways
            {
                self.settingsService.setAllowedLocationPermission()
            }
            
            self.finish()
        }
    }
    
    override func finish()
    {
        self.locationManager.delegate = nil
        self.onboardingPageViewController.goToNextPage(forceNext: true)
        self.disposeBag = nil
    }
    
    func onLifecycleEvent(event: LifecycleEvent)
    {
        if event == .movedToForeground
            && self.onboardingPageViewController.isCurrent(page: self)
            && !self.settingsService.hasLocationPermission
        {
            self.locationManager.requestAlwaysAuthorization()
        }
    }
}
