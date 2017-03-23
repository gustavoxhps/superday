import Foundation
@testable import teferi

class MockTrackEventService:TrackEventService
{
    var mockEvents:[TrackEvent] = []
    
    func getEvents() -> [ TrackEvent ]
    {
        return mockEvents
    }
}
