import Foundation
@testable import teferi
import CoreLocation

extension TrackEvent
{
    static var baseMockEvent:TrackEvent {
        return Location.asTrackEvent(
            Location(fromCLLocation: CLLocation.baseLocation)
        )
    }
    
    func delay(hours:Double = 0, minutes:Double = 0, seconds:Double = 0) -> TrackEvent
    {
        switch self {
        case .newHealthSample(let sample):
            return TrackEvent.newHealthSample(
                sample: HealthSample(
                    withIdentifier: sample.identifier,
                    startTime: sample.startTime.addingTimeInterval(hours*60*60 + minutes*60 + seconds),
                    endTime: sample.endTime.addingTimeInterval(seconds),
                    value: sample.value
                )
            )
        case .newLocation(let location):
            return TrackEvent.newLocation(
                location: Location(
                    timestamp: location.timestamp.addingTimeInterval(hours*60*60 + minutes*60 + seconds),
                    latitude: location.latitude,
                    longitude: location.longitude,
                    speed: location.speed,
                    course: location.course,
                    altitude: location.altitude,
                    verticalAccuracy: location.verticalAccuracy,
                    horizontalAccuracy: location.horizontalAccuracy
                )
            )
        }
    }
    
    func offset(meters:Double) -> TrackEvent
    {
        switch self {
            
        case .newHealthSample(let sample):
            return TrackEvent.newHealthSample(
                sample: HealthSample(
                    withIdentifier: sample.identifier,
                    startTime: sample.startTime,
                    endTime: sample.endTime,
                    value: sample.value
                )
            )
            
        case .newLocation(let oldLocation):
            
            let cllocation = oldLocation.toCLLocation().offset(.north, meters:meters)
            let location = Location(fromCLLocation: cllocation)
            
            return TrackEvent.newLocation(
                location: Location(
                    timestamp: location.timestamp,
                    latitude: location.latitude,
                    longitude: location.longitude,
                    speed: location.speed,
                    course: location.course,
                    altitude: location.altitude,
                    verticalAccuracy: location.verticalAccuracy,
                    horizontalAccuracy: location.horizontalAccuracy
                )
            )
        }
    }
}
