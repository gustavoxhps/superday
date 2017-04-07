import CoreLocation

extension CLLocation
{
    func isMoreAccurate(than other: CLLocation) -> Bool
    {
        return self.horizontalAccuracy < other.horizontalAccuracy
    }
    
    func isSignificantlyDifferent(fromLocation other: CLLocation) -> Bool
    {
        let distance = self.distance(from: other)
        return distance > Constants.significantDistanceThreshold
    }
}
