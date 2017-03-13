import Foundation
import CoreLocation

enum TrackEvent
{
    case newLocation(location: Location)
}

extension TrackEvent
{
    static func toTrackEvent(_ location: Location) -> TrackEvent
    {
        return .newLocation(location: location)
    }
}
