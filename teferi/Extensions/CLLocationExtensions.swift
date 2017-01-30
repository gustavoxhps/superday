import CoreLocation

extension CLLocation
{
    func isMoreAccurate(than other: CLLocation) -> Bool
    {
        return self.horizontalAccuracy < other.horizontalAccuracy
    }
}

extension CLLocation : KNNInstance
{
    var attributes : [KNNAttributeType: AnyObject]
    {
        return [.location: self, .timestamp: self.timestamp as AnyObject]
    }
    var label : String
    {
        return ""
    }
}
