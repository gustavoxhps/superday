@testable import teferi

class MockHealthKitService : HealthKitService
{
    func startHealthKitTracking() {}
    
    func stopHealthKitTracking() {}
    
    func requestAuthorization(completion: ((Bool)->())?) { completion?(true) }
}
