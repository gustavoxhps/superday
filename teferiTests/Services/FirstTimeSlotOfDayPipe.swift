import XCTest
import UserNotifications
import Nimble
import CoreLocation
@testable import teferi

class FirstTimeSlotOfDayPipeTests : XCTestCase
{
    private var timeService : MockTimeService!
    private var timeSlotService : MockTimeSlotService!
    
    private var pipe : FirstTimeSlotOfDayPipe!
    
    override func setUp()
    {
        self.timeService = MockTimeService()
        self.timeSlotService = MockTimeSlotService(timeService: self.timeService,
                                                   locationService: MockLocationService())
        
        self.pipe = FirstTimeSlotOfDayPipe(timeService: self.timeService,
                                           timeSlotService: self.timeSlotService)
    }
    
    func testThePipeCreatesATimeSlotIfTheresNoDataForTheCurrentDayBothPersistedAndInThePipe()
    {
        let result = self.pipe.process(data: [])
        
        expect(result.count).to(equal(1))
    }
    
    func testThePipeDoesNotTouchDataIfThereAreSlotsInThePipe()
    {
        let result = self.pipe.process(data: [ TemporaryTimeSlot(start: self.timeService.now) ])
        
        expect(result.count).to(equal(1))
    }
    
    func testThePipeDoesNotTouchDataIfThereArePersistedTimeSlotsForTheDay()
    {
        self.timeSlotService.addTimeSlot(withStartTime: self.timeService.now, category: .unknown, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        
        let result = self.pipe.process(data: [])
        
        expect(result.count).to(equal(0))
    }
}
