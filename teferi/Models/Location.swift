import Foundation
import UIKit
import CoreLocation

class Location
{
    let timestamp : Date
    let latitude : Double
    let longitude : Double
    
    init(fromLocation location: CLLocation)
    {
        self.timestamp = location.timestamp
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }
}
