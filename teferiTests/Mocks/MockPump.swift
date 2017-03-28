@testable import teferi

class MockPump : Pump
{
    var timeSlotsToReturn = [TemporaryTimeSlot]()
    
    func run() -> [TemporaryTimeSlot]
    {
        return timeSlotsToReturn
    }
}
