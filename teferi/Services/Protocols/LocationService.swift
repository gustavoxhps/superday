import CoreLocation
import RxSwift

/// Responsible for tracking the users location.
protocol LocationService
{
    //MARK: Methods
    
    ///Starts the tracking service.
    func startLocationTracking()
    
    ///Gets the last known position
    func getLastKnownLocation() -> CLLocation?
    
    /**
     Observable that emits events when new locations are received.
     */
    var locationObservable : Observable<CLLocation> { get }
}
