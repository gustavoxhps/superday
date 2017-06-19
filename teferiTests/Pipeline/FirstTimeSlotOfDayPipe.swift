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
        noon = Date().ignoreTimeComponents().addingTimeInterval(12 * 60 * 60)
        timeService = MockTimeService()
        timeSlotService = MockTimeSlotService(timeService: timeService,
                                                   locationService: MockLocationService())
        
        timeService.mockDate = noon
        
        pipe = FirstTimeSlotOfDayPipe(timeService: timeService,
                                           timeSlotService: timeSlotService)
    }
    
    func testThePipeCreatesInitialTimeSlotIfNoneExistYet()
    {
        let result = pipe.process(timeline: [])
        
        expect(result.count).to(equal(1))
        expect(result.first!.start).to(equal(timeService.now))
    }
    
    func testThePipeCreatesATimeSlotIfThereIsNoTimeSlotPersistedTodayAndNoTimeSlotStartingTodayInThePipe()
    {
        timeSlotService.addTimeSlot(withStartTime: timeService.now.addingTimeInterval(-24*60*60), category: .unknown, categoryWasSetByUser: false, tryUsingLatestLocation: false)

        let result = pipe.process(timeline: [TemporaryTimeSlot(start: timeService.now.yesterday) ])
        
        expect(result.count).to(equal(2))
        expect(result.first!.start).to(equal(timeService.now.yesterday))
        expect(result.last!.start).to(equal(timeService.now))
    }
    
    func testThePipeCreatesATimeSlotIfTheresNoDataForTheCurrentDayBothPersistedAndInThePipe()
    {
        timeSlotService.addTimeSlot(withStartTime: timeService.now.addingTimeInterval(-24*60*60), category: .unknown, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        
        let result = pipe.process(timeline: [])
        
        expect(result.count).to(equal(1))
        expect(result.first!.start).to(equal(timeService.now))
    }
    
    func testThePipeDoesNotTouchDataIfThereAreSlotsInThePipe()
    {
        timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .unknown, categoryWasSetByUser: false, tryUsingLatestLocation: false)

        let result = pipe.process(timeline: [ TemporaryTimeSlot(start: timeService.now) ])
        
        expect(result.count).to(equal(1))
    }
    
    func testThePipeDoesNotTouchDataIfThereArePersistedTimeSlotsForTheDay()
    {
        timeSlotService.addTimeSlot(withStartTime: timeService.now, category: .unknown, categoryWasSetByUser: false, tryUsingLatestLocation: false)
        
        let result = pipe.process(timeline: [])
        
        expect(result.count).to(equal(0))
    }
}
