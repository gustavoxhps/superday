import CoreLocation

extension CLLocation
{
    func isMoreAccurate(than other: CLLocation) -> Bool
    {
        return self.horizontalAccuracy < other.horizontalAccuracy
    }
}
