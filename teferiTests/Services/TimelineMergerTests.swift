import XCTest
import UserNotifications
import Nimble
import CoreLocation
@testable import teferi

class TimelineMergerTests : XCTestCase
{
    private typealias SlotTimeDiff = (start: TimeInterval, end: TimeInterval?)
    private typealias SlotTimeDiffWithCategory = (start: TimeInterval, end: TimeInterval?, category: teferi.Category)
    
    private var noon : Date!
    private var baseSlot : TemporaryTimeSlot!
    
    private var timelineMerger : TimelineMerger!
    
    private var locationTemporaryTimelineGenerator : MockTimelineGenerator!
    private var healthKitTemporaryTimelineGenerator : MockTimelineGenerator!
    
    override func setUp()
    {
        self.noon = Date().ignoreTimeComponents().addingTimeInterval(12 * 60 * 60)
        self.baseSlot = TemporaryTimeSlot(start: noon,
                                        end: nil,
                                        smartGuess: nil,
                                        category: Category.unknown,
                                        location: nil)
        
        self.locationTemporaryTimelineGenerator = MockTimelineGenerator()
        self.healthKitTemporaryTimelineGenerator = MockTimelineGenerator()
        
        self.timelineMerger = TimelineMerger(withTimelineGenerators: self.locationTemporaryTimelineGenerator, self.healthKitTemporaryTimelineGenerator)
    }
    
    func testTheMergerCreatesATimelineThatUsesTheIntersectionOfAllTimeSlots()
    {
        /*
         HealthKit   : [   |    |     | ]
         CoreLocation: [ |   |     |    ]
         Merged      : [ | | |  |  |  | ]
         */
        
        self.locationTemporaryTimelineGenerator.timeSlotsToReturn =
            [ (0, 100), (100, 400), (400, 0900), (0900, 1300) ].map(toTempTimeSlot)
        
        self.healthKitTemporaryTimelineGenerator.timeSlotsToReturn =
            [ (0, 300), (300, 700), (700, 1200), (1200, 1300) ].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ (0, 100), (100, 300), (300, 400), (400, 700), (700, 900), (900, 1200), (1200, 1300), (1300, nil) ]
                .map(toTempTimeSlot)
        
        self.timelineMerger
            .generateTemporaryTimeline()
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedTimeline[i]) }
    }
    
    func testCommutesHaveGreaterPriorityOverOtherCategories()
    {
        /*
         C = commute
         W = work
         Otherwise, unknown
         
         HealthKit   : [   C    |     | ]
         CoreLocation: [ |   |  W  |    ]
         Merged      : [C| C |C |W |  | ]
         */
        
        self.locationTemporaryTimelineGenerator.timeSlotsToReturn =
            [ (0000, 0100, teferi.Category.unknown),
              (0100, 0400, teferi.Category.unknown),
              (0400, 0900, teferi.Category.work   ),
              (0900, 1300, teferi.Category.unknown) ].map(toTempTimeSlot)
        
        self.healthKitTemporaryTimelineGenerator.timeSlotsToReturn =
            [ (0000, 0700, teferi.Category.commute),
              (0700, 1200, teferi.Category.unknown),
              (1200, 1300, teferi.Category.unknown) ].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ (0000, 0100, teferi.Category.commute),
              (0100, 0400, teferi.Category.commute),
              (0400, 0700, teferi.Category.commute),
              (0700, 0900, teferi.Category.work),
              (0900, 1200, teferi.Category.unknown),
              (1200, 1300, teferi.Category.unknown),
              (1300, nil , teferi.Category.unknown) ]
                .map(toTempTimeSlot)
        
        self.timelineMerger
            .generateTemporaryTimeline()
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedTimeline[i]) }
    }
    
    private func toTempTimeSlot(dates: SlotTimeDiff) -> TemporaryTimeSlot
    {
        return self.baseSlot.with(start: self.date(dates.start),
                                  end: dates.end == nil ? nil : self.date(dates.end!))
    }
    
    private func toTempTimeSlot(slot: SlotTimeDiffWithCategory) -> TemporaryTimeSlot
    {
        return self.baseSlot.with(start: self.date(slot.start),
                                  end: slot.end == nil ? nil : self.date(slot.end!),
                                  category: slot.category)
    }
    
    private func date(_ timeInterval: TimeInterval) -> Date
    {
        return noon.addingTimeInterval(timeInterval)
    }
    
    private func compare(timeSlot actualTimeSlot: TemporaryTimeSlot, to expectedTimeSlot: TemporaryTimeSlot)
    {
        expect(actualTimeSlot.start).to(equal(expectedTimeSlot.start))
        expect(actualTimeSlot.category).to(equal(expectedTimeSlot.category))
        
        if expectedTimeSlot.end == nil
        {
            expect(actualTimeSlot.end).to(beNil())
        }
        else
        {
            expect(actualTimeSlot.end).to(equal(expectedTimeSlot.end))
        }
    }
}
