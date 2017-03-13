import Foundation
import CoreLocation

enum TrackEvent
{
    case newLocation(location: CLLocation)
}

extension TrackEvent
{
    static func toTrackEvent(_ location: CLLocation) -> TrackEvent
    {
        return .newLocation(location: location)
    }
}
