import Foundation
import HealthKit

final class HealthSample : EventData
{
    // MARK: Fields
    let value : Any?
    let endTime : Date
    let startTime : Date
    let identifier : String
    
    // MARK: Init
    init(withIdentifier identifier: String, startTime: Date, endTime: Date, value: Any?)
    {
        self.value = value
        self.endTime = endTime
        self.startTime = startTime
        self.identifier = identifier
    }
    
    init(fromHKSample sample: HKSample)
    {
        self.identifier = sample.sampleType.identifier
        self.startTime = sample.startDate
        self.endTime = sample.endDate
        self.value = sample.tryGetValue()
    }
    
    // MARK: EventData implementation
    static func asTrackEvent(_ instance: HealthSample) -> TrackEvent
    {
        return .newHealthSample(sample: instance)
    }
    static func fromTrackEvent(event: TrackEvent) -> HealthSample?
    {
        guard case let .newHealthSample(sample) = event else { return nil }
        
        return sample
    }
    
    // MARK: Equatable implementation
    public static func ==(lhs: HealthSample, rhs: HealthSample) -> Bool
    {
        return lhs.endTime == rhs.endTime &&
            lhs.startTime == rhs.startTime &&
            lhs.identifier == rhs.identifier
    }
}
