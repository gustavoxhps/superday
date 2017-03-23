@testable import teferi

class MockPump : Pump
{
    var timeSlotsToReturn = [TemporaryTimeSlot]()
    
    func start() -> [TemporaryTimeSlot]
    {
        return timeSlotsToReturn
    }
}
