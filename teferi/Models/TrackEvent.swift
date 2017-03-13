import Foundation
import HealthKit
import CoreLocation

enum TrackEvent
{
    case newLocation(location: Location)
    case newHealthSample(sample: HealthSample)
}

extension TrackEvent
{
    static func toTrackEvent(_ location: Location) -> TrackEvent
    {
        return .newLocation(location: location)
    }
    
    static func toTrackEvent(_ sample: HealthSample) -> TrackEvent
    {
        return .newHealthSample(sample: sample)
    }
}
