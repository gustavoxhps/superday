import XCTest
import UserNotifications
import Nimble
import CoreLocation
@testable import teferi

fileprivate struct TestData
{
    let startOffset : TimeInterval
    let endOffset : TimeInterval?
    let category : teferi.Category
    let includeLocation : Bool
    let includeSmartGuess : Bool
}

fileprivate extension TestData
{
    init(startOffset: TimeInterval, endOffset: TimeInterval?)
    {
        self.startOffset = startOffset
        self.endOffset = endOffset
        self.category = .unknown
        self.includeSmartGuess = false
        self.includeLocation = false
    }
    
    init(startOffset: TimeInterval,
         endOffset: TimeInterval?,
         _ category: teferi.Category,
         includeSmartGuess: Bool = false,
         includeLocation: Bool = false)
    {
        self.startOffset = startOffset
        self.endOffset = endOffset
        self.category = category
        self.includeSmartGuess = includeSmartGuess
        self.includeLocation = includeLocation
    }
}

class TimelineMergerTests : XCTestCase
{
    private var noon : Date!
    private var baseSlot : TemporaryTimeSlot!
    private let baseLocation = Location(fromCLLocation: CLLocation())
    
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
         CoreLocation: [ |   |     |    ]
         HealthKit   : [   |    |     | ]
         Merged      : [ | | |  |  |  | ]
         */
        
        self.locationTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100),
              TestData(startOffset: 0100, endOffset: 0400),
              TestData(startOffset: 0400, endOffset: 0900),
              TestData(startOffset: 0900, endOffset: 1300) ].map(toTempTimeSlot)
        
        self.healthKitTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0300),
              TestData(startOffset: 0300, endOffset: 0700),
              TestData(startOffset: 0700, endOffset: 1200),
              TestData(startOffset: 1200, endOffset: 1300) ].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: 0000, endOffset: 0100),
              TestData(startOffset: 0100, endOffset: 0300),
              TestData(startOffset: 0300, endOffset: 0400),
              TestData(startOffset: 0400, endOffset: 0700),
              TestData(startOffset: 0700, endOffset: 0900),
              TestData(startOffset: 0900, endOffset: 1200),
              TestData(startOffset: 1200, endOffset: 1300),
              TestData(startOffset: 1300, endOffset: nil ) ].map(toTempTimeSlot)
        
        self.timelineMerger
            .generateTemporaryTimeline()
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedTimeline[i]) }
    }
    
    func testTimelinesWithEquallySizedTimeSlotsDoNotCreateZeroDurationSlots()
    {
        /*
         CoreLocation: [ |   |     |    ]
         HealthKit   : [ |   |  |     | ]
         Merged      : [ |   |  |  |  | ]
         */
        
        self.locationTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100),
              TestData(startOffset: 0100, endOffset: 0400),
              TestData(startOffset: 0400, endOffset: 0900),
              TestData(startOffset: 0900, endOffset: 1300) ].map(toTempTimeSlot)
        
        self.healthKitTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100),
              TestData(startOffset: 0100, endOffset: 0400),
              TestData(startOffset: 0400, endOffset: 0600),
              TestData(startOffset: 0600, endOffset: 1100),
              TestData(startOffset: 1100, endOffset: 1300) ].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: 0000, endOffset: 0100),
              TestData(startOffset: 0100, endOffset: 0400),
              TestData(startOffset: 0400, endOffset: 0600),
              TestData(startOffset: 0600, endOffset: 0900),
              TestData(startOffset: 0900, endOffset: 1100),
              TestData(startOffset: 1100, endOffset: 1300),
              TestData(startOffset: 1300, endOffset: nil ) ].map(toTempTimeSlot)
        
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
         
         CoreLocation: [ |   |  W  |    ]
         HealthKit   : [   C    |     | ]
         Merged      : [C| C |C |W |  | ]
         */
        
        self.locationTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.unknown),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.unknown),
              TestData(startOffset: 0400, endOffset: 0900, teferi.Category.work   ),
              TestData(startOffset: 0900, endOffset: 1300, teferi.Category.unknown) ].map(toTempTimeSlot)
        
        self.healthKitTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0700, teferi.Category.commute),
              TestData(startOffset: 0700, endOffset: 1200, teferi.Category.unknown),
              TestData(startOffset: 1200, endOffset: 1300, teferi.Category.unknown) ].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.commute),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.commute),
              TestData(startOffset: 0400, endOffset: 0700, teferi.Category.commute),
              TestData(startOffset: 0700, endOffset: 0900, teferi.Category.work   ),
              TestData(startOffset: 0900, endOffset: 1200, teferi.Category.unknown),
              TestData(startOffset: 1200, endOffset: 1300, teferi.Category.unknown),
              TestData(startOffset: 1300, endOffset: nil , teferi.Category.unknown) ].map(toTempTimeSlot)
        
        self.timelineMerger
            .generateTemporaryTimeline()
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedTimeline[i]) }
    }
    
    func testCategoriesThatAreBackedByASmartGuessesHaveHigherPriorityOverOnesThatAreNot()
    {
        /*
         C = commute
         W = work
         F = food
         Lowercase = No SmartGuess
         Otherwise, unknown
         
         CoreLocation: [ |   |  W  |  w ]
         HealthKit   : [   c    |     |F]
         Merged      : [c| c |c |W | w|F]
         */
        
        self.locationTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 0400, endOffset: 0900, teferi.Category.work   , includeSmartGuess: true),
              TestData(startOffset: 0900, endOffset: 1300, teferi.Category.work   , includeSmartGuess: false)].map(toTempTimeSlot)
        
        self.healthKitTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0700, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0700, endOffset: 1200, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 1200, endOffset: 1300, teferi.Category.food   , includeSmartGuess: true )].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0400, endOffset: 0700, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0700, endOffset: 0900, teferi.Category.work   , includeSmartGuess: true),
              TestData(startOffset: 0900, endOffset: 1200, teferi.Category.work   , includeSmartGuess: false),
              TestData(startOffset: 1200, endOffset: 1300, teferi.Category.food   , includeSmartGuess: true),
              TestData(startOffset: 1300, endOffset: nil , teferi.Category.unknown, includeSmartGuess: false) ]
                .map(toTempTimeSlot)
        
        self.timelineMerger
            .generateTemporaryTimeline()
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedTimeline[i]) }
    }
    
    func testCommutesWithSmartGuessesHavePriorityOverCommutesWithoutIt()
    {
        /*
         C = commute with SmartGuess
         c = commute with no SmartGuess
         Otherwise, unknown
         
         CoreLocation: [ |   |  c  |    ]
         HealthKit   : [   C    |     | ]
         Merged      : [C| C |C |c |  | ]
         */
        
        self.locationTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 0400, endOffset: 0900, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0900, endOffset: 1300, teferi.Category.unknown, includeSmartGuess: false)].map(toTempTimeSlot)
        
        self.healthKitTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0700, teferi.Category.commute, includeSmartGuess: true ),
              TestData(startOffset: 0700, endOffset: 1200, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 1200, endOffset: 1300, teferi.Category.unknown, includeSmartGuess: false)].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.commute, includeSmartGuess: true ),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.commute, includeSmartGuess: true ),
              TestData(startOffset: 0400, endOffset: 0700, teferi.Category.commute, includeSmartGuess: true ),
              TestData(startOffset: 0700, endOffset: 0900, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0900, endOffset: 1200, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 1200, endOffset: 1300, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 1300, endOffset: nil , teferi.Category.unknown, includeSmartGuess: false) ]
                .map(toTempTimeSlot)
        
        self.timelineMerger
            .generateTemporaryTimeline()
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedTimeline[i]) }
    }
    
    func testCommutesWithSmartGuessesHavePriorityOverCommutesWithoutItRegardlessOfTheOrderOfTheSourcesSuggestingCommute()
    {
        /*
         C = commute with SmartGuess
         c = commute with no SmartGuess
         Otherwise, unknown
         
         CoreLocation: [ |   |  C  |    ]
         HealthKit   : [   c    |     | ]
         Merged      : [c| c |C |C |  | ]
         */
        
        self.locationTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 0400, endOffset: 0900, teferi.Category.commute, includeSmartGuess: true ),
              TestData(startOffset: 0900, endOffset: 1300, teferi.Category.unknown, includeSmartGuess: false)].map(toTempTimeSlot)
        
        self.healthKitTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0700, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0700, endOffset: 1200, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 1200, endOffset: 1300, teferi.Category.unknown, includeSmartGuess: false)].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0400, endOffset: 0700, teferi.Category.commute, includeSmartGuess: true ),
              TestData(startOffset: 0700, endOffset: 0900, teferi.Category.commute, includeSmartGuess: true ),
              TestData(startOffset: 0900, endOffset: 1200, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 1200, endOffset: 1300, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 1300, endOffset: nil , teferi.Category.unknown, includeSmartGuess: false) ]
                .map(toTempTimeSlot)
        
        self.timelineMerger
            .generateTemporaryTimeline()
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedTimeline[i]) }
    }
    
    func testALocationShouldAlwaysBeSelectedWhenAvailableEvenIfTheTimeSlotProvidingItHasTheWrongCategory()
    {
        /*
         C = Commute
         L = Unknown with location
         WL = Work with location
         CL = Commute with location
         Otherwise, unknown
         
         CoreLocation: [ | WL|     |  L ]
         HealthKit   : [   C    |     | ]
         Merged      : [C| CL|C |  | L|L]
         */
        
        self.locationTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.unknown, includeLocation: false),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.work   , includeLocation: true ),
              TestData(startOffset: 0400, endOffset: 0900, teferi.Category.unknown, includeLocation: false),
              TestData(startOffset: 0900, endOffset: 1300, teferi.Category.unknown, includeLocation: true ) ].map(toTempTimeSlot)
        
        self.healthKitTemporaryTimelineGenerator.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0700, teferi.Category.commute),
              TestData(startOffset: 0700, endOffset: 1200, teferi.Category.unknown),
              TestData(startOffset: 1200, endOffset: 1300, teferi.Category.unknown) ].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.commute, includeLocation: false),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.commute, includeLocation: true ),
              TestData(startOffset: 0400, endOffset: 0700, teferi.Category.commute, includeLocation: false),
              TestData(startOffset: 0700, endOffset: 0900, teferi.Category.unknown, includeLocation: false),
              TestData(startOffset: 0900, endOffset: 1200, teferi.Category.unknown, includeLocation: true ),
              TestData(startOffset: 1200, endOffset: 1300, teferi.Category.unknown, includeLocation: true ),
              TestData(startOffset: 1300, endOffset: nil , teferi.Category.unknown, includeLocation: false) ].map(toTempTimeSlot)
        
        self.timelineMerger
            .generateTemporaryTimeline()
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedTimeline[i]) }
    }
    
    
    private func compare(timeSlot actualTimeSlot: TemporaryTimeSlot, to expectedTimeSlot: TemporaryTimeSlot)
    {
        expect(actualTimeSlot.start).to(equal(expectedTimeSlot.start))
        expect(actualTimeSlot.category).to(equal(expectedTimeSlot.category))
        
        compareOptional(actualTimeSlot.end, expectedTimeSlot.end)
        compareOptional(actualTimeSlot.location, expectedTimeSlot.location)
        compareOptional(actualTimeSlot.smartGuess, expectedTimeSlot.smartGuess)
    }
    
    private func compareOptional<T : Equatable>(_ actual: T?, _ expected: T?)
    {
        if expected == nil
        {
            expect(actual).to(beNil())
        }
        else
        {
            expect(actual).to(equal(expected))
        }
    }
    
    private func toTempTimeSlot(data: TestData) -> TemporaryTimeSlot
    {
        return self.baseSlot.with(start: self.date(data.startOffset),
                                  end: data.endOffset != nil ? self.date(data.endOffset!) : nil,
                                  smartGuess: data.includeSmartGuess ? self.smartGuess(withCategory: data.category) : nil,
                                  category: data.category,
                                  location: data.includeLocation ? self.baseLocation : nil)
    }
    
    private func date(_ timeInterval: TimeInterval) -> Date
    {
        return noon.addingTimeInterval(timeInterval)
    }
    
    private func smartGuess(withCategory category: teferi.Category) -> SmartGuess
    {
        return SmartGuess(withId: 0, category: category, location: CLLocation(), lastUsed: noon)
    }
}

extension SmartGuess : Equatable
{
    public static func ==(lhs: SmartGuess, rhs: SmartGuess) -> Bool
    {
        return lhs.id == rhs.id &&
            lhs.errorCount == rhs.errorCount &&
            lhs.category == rhs.category &&
            lhs.lastUsed == rhs.lastUsed
    }
}
