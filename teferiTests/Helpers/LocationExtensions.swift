import CoreLocation
import Foundation

private let earthRadius = 6_378_000.0
private let metersToLatitudeFactor = 1.0 / 111_000

enum Direction:UInt32
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
        let newCoordinate = coordinate.offset(direction, meters: meters)
        let newLocation = CLLocation(coordinate: newCoordinate,
                                     altitude: altitude,
                                     horizontalAccuracy: horizontalAccuracy,
                                     verticalAccuracy: verticalAccuracy,
                                     timestamp: timestamp ?? self.timestamp)
        return newLocation
    }
    
    func offset(_ direction: Direction?, meters: Double = 0, seconds: TimeInterval = 0) -> CLLocation
    {
        let newCoordinate:CLLocationCoordinate2D
        if let direction = direction {
            newCoordinate = coordinate.offset(direction, meters: meters)
        } else {
            newCoordinate = coordinate
        }
        let newLocation = CLLocation(coordinate: newCoordinate,
                                     altitude: altitude,
                                     horizontalAccuracy: horizontalAccuracy,
                                     verticalAccuracy: verticalAccuracy,
                                     timestamp: timestamp.addingTimeInterval(seconds))
        return newLocation
    }
    
    
    func randomOffset(withAccuracy accuracy:Double? = nil) -> CLLocation
    {
        
        let newCoordinate = coordinate.offset(
            Direction(rawValue: arc4random_uniform(4))!,
            meters: randomBetweenNumbers(firstNum: 10, secondNum: 100000)
        )
        
        guard let accuracy = accuracy else {
            return CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
        }
        
        return CLLocation(
            coordinate: newCoordinate,
            altitude: CLLocationDistance(),
            horizontalAccuracy: CLLocationAccuracy(exactly: accuracy)!,
            verticalAccuracy: CLLocationAccuracy(exactly: accuracy)!,
            timestamp: Date())
    }
    
    
    func with(accuracy:Double) -> CLLocation
    {
        return CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: accuracy,
            verticalAccuracy: accuracy,
            course: course,
            speed: speed,
            timestamp: timestamp)
    }
}

fileprivate func randomBetweenNumbers(firstNum: Double, secondNum: Double) -> Double{
    return Double(arc4random()) / Double(Int.max) * (secondNum - firstNum) + firstNum

}
