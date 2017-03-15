import Foundation
import HealthKit

class HealthSample : Equatable
{
    public static func ==(lhs: HealthSample, rhs: HealthSample) -> Bool
    {
        return lhs.endTime == rhs.endTime &&
               lhs.startTime == rhs.startTime &&
               lhs.identifier == rhs.identifier
    }

    let value : Any?
    let endTime : Date
    let startTime : Date
    let identifier : String
    
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
}
