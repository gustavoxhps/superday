import Fabric
import Crashlytics

class FabricMetricsService : MetricsService
{
    ///Perform any framework specific initialization
    func initialize()
    {
        #if !DEBUG
            Fabric.with([Answers.self, Crashlytics.self])
        #endif
    }
    
    ///Used to send custom events to the framework
    func log(event: CustomEvent)
    {
        #if !DEBUG
            Answers.logCustomEvent(withName: event.rawValue, customAttributes: [:])
        #endif
    }
}
