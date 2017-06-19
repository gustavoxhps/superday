import Foundation
import CoreLocation
import RxSwift
@testable import teferi

class MockLocationService : LocationService
{
    //MARK: Fields
    private var lastLocation = CLLocation()
    private var eventSubject = PublishSubject<CLLocation>()
    
    //MARK: Properties
    private(set) var locationStarted = false
    var useNilOnLastKnownLocation = false
    
    //MARK: LocationService implementation
    var isInBackground : Bool = false
    
    func startLocationTracking()
    {
        locationStarted = true
    }
    
    func stopLocationTracking()
    {
        locationStarted = false
    }
    
    func getLastKnownLocation() -> CLLocation?
    {
        return useNilOnLastKnownLocation ? nil : lastLocation
    }
    
    var eventObservable : Observable<TrackEvent>
    {
        return eventSubject
                .asObservable()
                .map(Location.init)
                .map(Location.asTrackEvent)
    }
    
    //MARK: Methods
    func sendNewTrackEvent(_ location: CLLocation)
    {
        lastLocation = location
        eventSubject.onNext(location)
    }
}
