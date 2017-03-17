import CoreLocation

extension CLLocation
{
    convenience init(fromLocation location: Location)
    {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        self.init(coordinate: coordinate,
                  altitude: location.altitude,
                  horizontalAccuracy: location.horizontalAccuracy,
                  verticalAccuracy: location.verticalAccuracy,
                  timestamp: location.timestamp)
    }
    
    func isMoreAccurate(than other: CLLocation) -> Bool
    {
        return self.horizontalAccuracy < other.horizontalAccuracy
    }
}
