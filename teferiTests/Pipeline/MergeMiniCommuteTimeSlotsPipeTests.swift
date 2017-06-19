import XCTest
import UserNotifications
import Nimble
import CoreLocation
@testable import teferi

class MergeMiniCommuteTimeSlotsPipeTests : XCTestCase
{
    private typealias TestData = TempTimelineTestData
    
    private var baseSlot : TemporaryTimeSlot!
    
    private var noon : Date!
    private var timeService : MockTimeService!
    
    private var pipe : MergeMiniCommuteTimeSlotsPipe!
    
    override func setUp()
    {
        noon = Date().ignoreTimeComponents().addingTimeInterval(12 * 60 * 60)
        timeService = MockTimeService()
        baseSlot = TemporaryTimeSlot(start: noon,
                                          end: nil,
                                          smartGuess: nil,
                                          category: Category.commute,
                                          location: nil)
        
        timeService.mockDate = noon
        
        pipe = MergeMiniCommuteTimeSlotsPipe(timeService: timeService)
    }
    
    func testThePipeMergesConsecutiveSmallCommutes()
    {
        /*
         Before: [ 3 | 3 ]
         After : [   6   ]
         */
        
        let initialData =
            [ TestData(startOffset: 000, endOffset: 180, isCommute: true),
              TestData(startOffset: 180, endOffset: 360, isCommute: true) ].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: 000, endOffset: 360, isCommute: true) ].map(toTempTimeSlot)
        
        pipe.process(timeline: initialData)
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedTimeline[i]) }
    }
    
    func testOnlyCommutesAreMerged()
    {
        /*
         Before: [ C | C | U ]
         After : [   C   | U ]
         */
        
        let initialData =
            [ TestData(startOffset: 000, endOffset: 180, isCommute: true ),
              TestData(startOffset: 180, endOffset: 360, isCommute: true ),
              TestData(startOffset: 360, endOffset: 540, isCommute: false) ].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: 000, endOffset: 360, isCommute: true ),
              TestData(startOffset: 360, endOffset: 540, isCommute: false) ].map(toTempTimeSlot)
        
        pipe.process(timeline: initialData)
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedTimeline[i]) }
    }
    
    func testBiggerTimeSlotsHavePrecedenceWhenBeingMerged()
    {
        /*
         Before: [ 3 | 3 | 3 |  5  | 3 |  3 ]
         After : [           20             ]
         */
        
        let initialData =
            [ TestData(startOffset: 0000, endOffset: 0180, isCommute: true),
              TestData(startOffset: 0180, endOffset: 0360, isCommute: true),
              TestData(startOffset: 0360, endOffset: 0540, isCommute: true),
              TestData(startOffset: 0540, endOffset: 0840, isCommute: true),
              TestData(startOffset: 0840, endOffset: 1020, isCommute: true),
              TestData(startOffset: 1020, endOffset: 1200, isCommute: true) ].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: 0000, endOffset: 1200, isCommute: true) ].map(toTempTimeSlot)
        
        pipe.process(timeline: initialData)
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedTimeline[i]) }
    }
    
    private func toTempTimeSlot(data: TestData) -> TemporaryTimeSlot
    {
        return baseSlot.with(start: date(data.startOffset),
                                  end: data.endOffset != nil ? date(data.endOffset!) : nil,
                                  smartGuess: nil,
                                  category: data.category,
                                  location: nil)
    }
    
    private func date(_ timeInterval: TimeInterval) -> Date
    {
        return noon.addingTimeInterval(timeInterval)
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

}
