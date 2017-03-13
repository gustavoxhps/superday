import CoreLocation

extension CLLocation
{
    convenience init(fromLocation location: Location)
    {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        self.init(coordinate: coordinate,
                  altitude: 0,
                  horizontalAccuracy: 0,
                  verticalAccuracy: 0,
                  timestamp: location.timestamp)
    }
    
    func isMoreAccurate(than other: CLLocation) -> Bool
    {
        return self.horizontalAccuracy < other.horizontalAccuracy
    }
}
