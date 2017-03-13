import Foundation
import HealthKit

class HealthSample
{
    let endTime : Date
    let startTime : Date
    let identifier : String
    let quantity : Any?
    
    init(withIdentifier identifier: String, startTime: Date, endTime: Date, quantity: Any?)
    {
        self.endTime = endTime
        self.quantity = quantity
        self.startTime = startTime
        self.identifier = identifier
    }
    
    init(fromHKSample sample: HKSample)
    {
        self.identifier = sample.sampleType.identifier
        self.startTime = sample.startDate
        self.endTime = sample.endDate
        self.quantity = sample.tryGetQuantity()
    }
}
