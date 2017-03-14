import CoreLocation
import RxSwift

protocol LocationService : EventSource
{
    func startLocationTracking()
    
    func stopLocationTracking()
    
    func getLastKnownLocation() -> CLLocation?
}
