import CoreLocation
import Foundation

private let earthRadius = 6_378_000.0
private let metersToLatitudeFactor = 1.0 / 111_000

enum Direction
{
    case north
    case south
    case west
    case east
}

extension CLLocationCoordinate2D
{
    func offset(_ direction: Direction, meters: Double) -> CLLocationCoordinate2D
    {
        let newLatitude : CLLocationDegrees
        let newLongitude : CLLocationDegrees
        
        switch(direction)
        {
            case .north:
                
                newLatitude = latitude + meters * metersToLatitudeFactor
                newLongitude = longitude
                break
            
            case .south:
                
                newLatitude = latitude + -meters * metersToLatitudeFactor
                newLongitude = longitude
                break
            
            case .west:
                
                newLatitude = latitude
                newLongitude = longitude + (-meters / earthRadius) * (180 / .pi) / cos(latitude * .pi / 180)
                break
            
            case .east:
                
                newLatitude = latitude
                newLongitude = longitude + (meters / earthRadius) * (180 / .pi) / cos(latitude * .pi / 180)
                break
        }
        
        let newCoordinate = CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
        return newCoordinate
    }
}

extension CLLocation
{
    func offset(_ direction: Direction, meters: Double, timestamp: Date? = nil) -> CLLocation
    {
        let newCoordinate = self.coordinate.offset(direction, meters: meters)
        let newLocation = CLLocation(coordinate: newCoordinate,
                                     altitude: self.altitude,
                                     horizontalAccuracy: self.horizontalAccuracy,
                                     verticalAccuracy: self.verticalAccuracy,
                                     timestamp: timestamp ?? self.timestamp)
        return newLocation
    }
}
