import CoreLocation
import RxSwift

protocol LocationService
{
    // MARK: Methods
    func startLocationTracking()
    
    func stopLocationTracking()
    
    func getLastKnownLocation() -> CLLocation?
}
