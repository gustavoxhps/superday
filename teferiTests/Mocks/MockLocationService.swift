import Foundation
import CoreLocation
import RxSwift
@testable import teferi

class MockLocationService : LocationService
{
    //MARK: Fields
    private var eventVariable = Variable(CLLocation())
    
    //MARK: Properties
    private(set) var locationStarted = false
    var useNilOnLastKnownLocation = false
    
    //MARK: LocationService implementation
    var isInBackground : Bool = false
    
    func startLocationTracking()
    {
        self.locationStarted = true
    }
    
    func stopLocationTracking()
    {
        self.locationStarted = false
    }
    
    func getLastKnownLocation() -> CLLocation?
    {
        return self.useNilOnLastKnownLocation ? nil : self.eventVariable.value
    }
    
    var eventObservable : Observable<TrackEvent> { return eventVariable.asObservable().map(Location.init(fromLocation:)).map(TrackEvent.toTrackEvent) }
    
    //MARK: Methods
    func sendNewTrackEvent(_ location: CLLocation)
    {
        self.eventVariable.value = location
    }
}
