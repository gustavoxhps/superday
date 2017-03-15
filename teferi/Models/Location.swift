import Foundation
import UIKit
import CoreLocation

class Location
{
    let timestamp : Date
    let latitude : Double
    let longitude : Double
    
    let speed : Double
    let course : Double
    let altitude : Double
    let verticalAccuracy : Double
    let horizontalAccuracy : Double
    
    init(timestamp: Date, latitude: Double, longitude: Double,
         speed: Double, course: Double, altitude: Double,
         verticalAccuracy: Double, horizontalAccuracy: Double)
    {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        
        self.speed = speed
        self.course = course
        self.altitude = altitude
        self.verticalAccuracy = verticalAccuracy
        self.horizontalAccuracy = horizontalAccuracy
    }
    
    
    init(fromCLLocation location: CLLocation)
    {
        self.timestamp = location.timestamp
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        
        self.speed = location.speed
        self.course = location.course
        self.altitude = location.altitude
        self.verticalAccuracy = location.verticalAccuracy
        self.horizontalAccuracy = location.horizontalAccuracy
    }
}
