protocol HealthKitService : EventSource
{
    func startHealthKitTracking()
    
    func stopHealthKitTracking()
    
    func requestAuthorization(completion: ((Bool)->())?)
}
