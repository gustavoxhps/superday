import Foundation
@testable import teferi

class MockMetricsService : MetricsService
{
    //MARK: Fields
    private var loggedEvents = [CustomEvent]()
    
    func initialize()
    {
        
    }
    
    func log(event: CustomEvent)
    {
        loggedEvents.append(event)
    }
    
    func didLog(event: CustomEvent) -> Bool
    {
        return loggedEvents.contains(where: {
            $0.name == event.name &&
            ($0.attributes["localHour"] as? Int) == (event.attributes["localHour"] as? Int) &&
            ($0.attributes["dayOfWeek"] as? Int) == (event.attributes["dayOfWeek"] as? Int) &&
            ($0.attributes["category"] as? String) == (event.attributes["category"] as? String) &&
            ($0.attributes["fromCategory"] as? String) == (event.attributes["fromCategory"] as? String) &&
            ($0.attributes["toCategory"] as? String) == (event.attributes["toCategory"] as? String) &&
            ($0.attributes["duration"] as? Int) == (event.attributes["duration"] as? Int)
        })
    }
}
