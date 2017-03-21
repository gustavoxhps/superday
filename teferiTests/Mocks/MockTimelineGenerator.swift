@testable import teferi

class MockTimelineGenerator : TemporaryTimelineGenerator
{
    var timeSlotsToReturn = [TemporaryTimeSlot]()
    
    func generateTemporaryTimeline() -> [TemporaryTimeSlot]
    {
        return timeSlotsToReturn
    }
}
