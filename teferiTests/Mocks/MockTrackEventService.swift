import Foundation
@testable import teferi

class MockTrackEventService : TrackEventService
{
    var mockEvents:[TrackEvent] = []
    
    func getEventData<T : EventData>(ofType: T.Type) -> [ T ]
    {
        return mockEvents.flatMap(T.fromTrackEvent)
    }
    
    func clearAllData()
    {
        mockEvents = [TrackEvent]()
    }
}
