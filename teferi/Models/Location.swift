import Foundation
import UIKit
import CoreLocation

final class Location : EventData
{
    // MARK: Fields
    let timestamp : Date
    let latitude : Double
    let longitude : Double
    
    let speed : Double
    let course : Double
    let altitude : Double
    let verticalAccuracy : Double
    let horizontalAccuracy : Double
    
    // MARK: Initializers
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
    
    // MARK: Methods
    func isCommute(fromLocation previousLocation:Location) -> Bool
    {
        return self.timestamp.timeIntervalSince(previousLocation.timestamp) < Constants.commuteDetectionLimit
    }
    
    func isMoreAccurate(than other: Location) -> Bool
    {
        return self.horizontalAccuracy < other.horizontalAccuracy
    }
    
    func isSignificantlyDifferent(fromLocation other: Location) -> Bool
    {
        let clLocation = self.toCLLocation()
        let otherCLLocation = other.toCLLocation()
        
        let distance = clLocation.distance(from: otherCLLocation)
        return distance > Constants.significantDistanceThreshold
    }
    
    func toCLLocation() -> CLLocation
    {
        let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        return CLLocation(coordinate: coordinate,                          altitude: self.altitude,
                          horizontalAccuracy: self.horizontalAccuracy,
                          verticalAccuracy: self.verticalAccuracy,
                          timestamp: self.timestamp)
    }
    
    // MARK: EventData implementation
    static func asTrackEvent(_ instance: Location) -> TrackEvent
    {
        return .newLocation(location: instance)
    }
    
    static func fromTrackEvent(event: TrackEvent) -> Location?
    {
        guard case let .newLocation(location) = event else { return nil }
            
        return location
    }

    // MARK: Equatable implementation
    public static func ==(lhs: Location, rhs: Location) -> Bool
    {
        return lhs.speed == rhs.speed &&
            lhs.course == rhs.course &&
            lhs.latitude == rhs.latitude &&
            lhs.altitude == rhs.altitude &&
            lhs.longitude == rhs.longitude &&
            lhs.timestamp == rhs.timestamp &&
            lhs.verticalAccuracy == rhs.verticalAccuracy &&
            lhs.horizontalAccuracy == rhs.horizontalAccuracy
    }
}
