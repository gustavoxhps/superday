import XCTest
import UserNotifications
import Nimble
import CoreLocation
@testable import teferi

class FirstTimeSlotOfDayPipeTests : XCTestCase
{
    private var noon : Date!
    private var timeService : MockTimeService!
    private var timeSlotService : MockTimeSlotService!
    
    private var pipe : FirstTimeSlotOfDayPipe!
    
    override func setUp()
    {
        self.noon = Date().ignoreTimeComponents().addingTimeInterval(12 * 60 * 60)
        self.timeService = MockTimeService()
        self.timeSlotService = MockTimeSlotService(timeService: self.timeService,
                                                   locationService: MockLocationService())
        
        self.timeService.mockDate = self.noon
        
        self.pipe = FirstTimeSlotOfDayPipe(timeService: self.timeService,
                                           timeSlotService: self.timeSlotService)
    }
    
    func testThePipeCreatesInitialTimeSlotIfNoneExistYet()
    {
        let result = self.pipe.process(timeline: [])
        
        expect(result.count).to(equal(1))
        expect(result.first!.start).to(equal(self.timeService.now))
    }
    
    func testThePipeCreatesATimeSlotIfThereIsNoTimeSlotPersistedTodayAndNoTimeSlotStartingTodayInThePipe()
    {
        self.timeSlotService.addTimeSlot(withStartTime: self.timeService.now.addingTimeInterval(-24*60*60), category: .unknown, categoryWasSetByUser: false, tryUsingLatestLocation: false)

        let result = self.pipe.process(timeline: [TemporaryTimeSlot(start: self.timeService.now.yesterday) ])
        
        expect(result.count).to(equal(2))
        expect(result.first!.start).to(equal(self.timeService.now.yesterday))
        expect(result.last!.start).to(equal(self.timeService.now))
    }
    
    func testThePipeCreatesATimeSlotIfTheresNoDataForTheCurrentDayBothPersistedAndInThePipe()
    {
        self.timeSlotService.addTimeSlot(withStartTime: self.timeService.now.addingTimeInterval(-24*60*60), category: .unknown, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        
        let result = self.pipe.process(timeline: [])
        
        expect(result.count).to(equal(1))
        expect(result.first!.start).to(equal(self.timeService.now))
    }
    
    func testThePipeDoesNotTouchDataIfThereAreSlotsInThePipe()
    {
        self.timeSlotService.addTimeSlot(withStartTime: self.timeService.now, category: .unknown, categoryWasSetByUser: false, tryUsingLatestLocation: false)

        let result = self.pipe.process(timeline: [ TemporaryTimeSlot(start: self.timeService.now) ])
        
        expect(result.count).to(equal(1))
    }
    
    func testThePipeDoesNotTouchDataIfThereArePersistedTimeSlotsForTheDay()
    {
        self.timeSlotService.addTimeSlot(withStartTime: self.timeService.now, category: .unknown, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        
        let result = self.pipe.process(timeline: [])
        
        expect(result.count).to(equal(0))
    }
}
