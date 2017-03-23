import Foundation
import HealthKit

extension HealthSample
{
    func categoryBasedOnSpeed(using fastMovingSpeedThreshold: Double) -> Category
    {
        return self.speed > fastMovingSpeedThreshold ?
            .commute :
            .unknown
    }
    
    var speed : Double
    {
        let duration = self.duration
        
        guard
            let quantity = self.value as? HKQuantity,
            quantity.is(compatibleWith: .meter()),
            duration > 0
        else { return 0.0 }
        
        let distance = quantity.doubleValue(for: HKUnit.meter())
        return distance / duration
    }
    
    var duration : Double
    {
        return self.endTime.timeIntervalSince(self.startTime)
    }
}
