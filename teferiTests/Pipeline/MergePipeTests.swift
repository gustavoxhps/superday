import XCTest
import UserNotifications
import Nimble
import CoreLocation
@testable import teferi

class MergePipeTests : XCTestCase
{
    private typealias TestData = TempTimelineTestData
    
    private var noon : Date!
    private var baseSlot : TemporaryTimeSlot!
    private let baseLocation = Location(fromCLLocation: CLLocation())
    
    private var data : [[TemporaryTimeSlot]]
    {
        return [ locationPump.run(), healthKitPump.run() ]
    }
    
    private var mergePipe : MergePipe!
    
    private var locationPump : MockPump!
    private var healthKitPump : MockPump!
    
    override func setUp()
    {
        noon = Date().ignoreTimeComponents().addingTimeInterval(12 * 60 * 60)
        baseSlot = TemporaryTimeSlot(start: noon, category: Category.unknown)
        
        locationPump = MockPump()
        healthKitPump = MockPump()
        
        mergePipe = MergePipe()
    }
    
    func testTheMergerCreatesATimelineThatUsesTheIntersectionOfAllTimeSlots()
    {
        /*
         CoreLocation: [ |   |     |    ]
         HealthKit   : [   |    |     | ]
         Merged      : [ | | |  |  |  | ]
         */
        
        locationPump.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100),
              TestData(startOffset: 0100, endOffset: 0400),
              TestData(startOffset: 0400, endOffset: 0900),
              TestData(startOffset: 0900, endOffset: 1300) ].map(toTempTimeSlot)
        
        healthKitPump.timeSlotsToReturn =
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
        
        mergePipe
            .process(timeline: data)
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
        
        locationPump.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100),
              TestData(startOffset: 0100, endOffset: 0400),
              TestData(startOffset: 0400, endOffset: 0900),
              TestData(startOffset: 0900, endOffset: 1300) ].map(toTempTimeSlot)
        
        healthKitPump.timeSlotsToReturn =
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
        
        mergePipe
            .process(timeline: data)
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
        
        locationPump.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.unknown),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.unknown),
              TestData(startOffset: 0400, endOffset: 0900, teferi.Category.work   ),
              TestData(startOffset: 0900, endOffset: 1300, teferi.Category.unknown) ].map(toTempTimeSlot)
        
        healthKitPump.timeSlotsToReturn =
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
              TestData(startOffset: 1300, endOffset: nil, teferi.Category.unknown) ].map(toTempTimeSlot)
        
        mergePipe
            .process(timeline: data)
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
        
        locationPump.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 0400, endOffset: 0900, teferi.Category.work, includeSmartGuess: true),
              TestData(startOffset: 0900, endOffset: 1300, teferi.Category.work, includeSmartGuess: false)].map(toTempTimeSlot)
        
        healthKitPump.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0700, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0700, endOffset: 1200, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 1200, endOffset: 1300, teferi.Category.food, includeSmartGuess: true )].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0400, endOffset: 0700, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0700, endOffset: 0900, teferi.Category.work, includeSmartGuess: true),
              TestData(startOffset: 0900, endOffset: 1200, teferi.Category.work, includeSmartGuess: false),
              TestData(startOffset: 1200, endOffset: 1300, teferi.Category.food, includeSmartGuess: true),
              TestData(startOffset: 1300, endOffset: nil, teferi.Category.unknown, includeSmartGuess: false) ]
                .map(toTempTimeSlot)
        
        mergePipe
            .process(timeline: data)
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
        
        locationPump.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 0400, endOffset: 0900, teferi.Category.commute, includeSmartGuess: false),
              TestData(startOffset: 0900, endOffset: 1300, teferi.Category.unknown, includeSmartGuess: false)].map(toTempTimeSlot)
        
        healthKitPump.timeSlotsToReturn =
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
              TestData(startOffset: 1300, endOffset: nil, teferi.Category.unknown, includeSmartGuess: false) ]
                .map(toTempTimeSlot)
        
        mergePipe
            .process(timeline: data)
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
        
        locationPump.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.unknown, includeSmartGuess: false),
              TestData(startOffset: 0400, endOffset: 0900, teferi.Category.commute, includeSmartGuess: true ),
              TestData(startOffset: 0900, endOffset: 1300, teferi.Category.unknown, includeSmartGuess: false)].map(toTempTimeSlot)
        
        healthKitPump.timeSlotsToReturn =
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
              TestData(startOffset: 1300, endOffset: nil, teferi.Category.unknown, includeSmartGuess: false) ]
                .map(toTempTimeSlot)
        
        mergePipe
            .process(timeline: data)
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedTimeline[i]) }
    }
    
    func testTheMergeAlgoShouldHandleMissingSlotsInSomeSources()
    {
        /*
         - = Covered by slots and unknown
         Otherwise, no slot info
         
         CoreLocation: [ |-|  ]
         HealthKit   : [------]
         Merged      : [-|-|--]
         */
        
        locationPump.timeSlotsToReturn =
            [ TestData(startOffset: 0100, endOffset: 0200) ].map(toTempTimeSlot)
        
        healthKitPump.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0600) ].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: 000, endOffset: 100),
              TestData(startOffset: 100, endOffset: 200),
              TestData(startOffset: 200, endOffset: 600),
              TestData(startOffset: 600, endOffset: nil ) ].map(toTempTimeSlot)
        
        mergePipe
            .process(timeline: data)
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
        
        locationPump.timeSlotsToReturn =
            [ TestData(startOffset: 0000, endOffset: 0100, teferi.Category.unknown, includeLocation: false),
              TestData(startOffset: 0100, endOffset: 0400, teferi.Category.work, includeLocation: true ),
              TestData(startOffset: 0400, endOffset: 0900, teferi.Category.unknown, includeLocation: false),
              TestData(startOffset: 0900, endOffset: 1300, teferi.Category.unknown, includeLocation: true ) ].map(toTempTimeSlot)
        
        healthKitPump.timeSlotsToReturn =
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
              TestData(startOffset: 1300, endOffset: nil, teferi.Category.unknown, includeLocation: false) ].map(toTempTimeSlot)
        
        mergePipe
            .process(timeline: data)
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
        return baseSlot.with(start: date(data.startOffset),
                                  end: data.endOffset != nil ? date(data.endOffset!) : nil,
                                  smartGuess: data.includeSmartGuess ? smartGuess(withCategory: data.category) : nil,
                                  category: data.category,
                                  location: data.includeLocation ? baseLocation : nil)
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
