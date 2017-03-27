import Foundation
import HealthKit
import CoreLocation

enum TrackEvent : Equatable
{
    public static func ==(lhs: TrackEvent, rhs: TrackEvent) -> Bool
    {
        //Don't try "optimizing" this with `case(_, _) return false`
        //We want a compiler warning when we add new track sources
        switch (lhs, rhs)
        {
            case (.newLocation(let a), .newLocation(let b)): return a == b
            case (.newHealthSample(let a), .newHealthSample(let b)): return a == b
            case (.newLocation, _): return false
            case (.newHealthSample, _): return false
        }
    }
    
    case newLocation(location: Location)
    case newHealthSample(sample: HealthSample)
}

protocol EventData : Equatable
{
    static func asTrackEvent(_ instance: Self) -> TrackEvent
    static func fromTrackEvent(event: TrackEvent) -> Self?
}
