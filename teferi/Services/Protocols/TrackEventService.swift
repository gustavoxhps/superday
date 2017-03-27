import Foundation

protocol TrackEventService
{
    // MARK: Methods
    func getEventData<T : EventData>(ofType: T.Type) -> [ T ]
    
    func clearAllData()
}
