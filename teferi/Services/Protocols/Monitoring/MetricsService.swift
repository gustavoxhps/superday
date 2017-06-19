import Foundation

///Provides metrics about the app's usage
protocol MetricsService
{
    //MARK: Methods
    
    ///Perform any framework specific initialization
    func initialize()
    
    ///Used to send custom events to the framework
    func log(event: CustomEvent)
}
