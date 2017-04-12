import HealthKit

extension HKSample
{
    func tryGetValue() -> Any?
    {
        if let quantitySample = self as? HKQuantitySample
        {
            return quantitySample.quantity
        }
        else if let categorySample = self as? HKCategorySample
        {
            return categorySample.value
        }
        
        return nil
    }
}
