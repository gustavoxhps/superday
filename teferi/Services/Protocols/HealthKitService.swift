protocol HealthKitService
{
    func startHealthKitTracking()
    
    func stopHealthKitTracking()
    
    func requestAuthorization(completion: ((Bool)->())?)
}
