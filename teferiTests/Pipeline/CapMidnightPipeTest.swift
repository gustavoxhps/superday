import XCTest
import Nimble
@testable import teferi

class CapMidnightPipeTest: XCTestCase
{
    private typealias TestData = TempTimelineTestData
    
    private var midnight : Date!
    private var baseSlot : TemporaryTimeSlot!
    private var timeService : MockTimeService!
    
    private var pipe : CapMidnightPipe!
    
    override func setUp()
    {
        super.setUp()
        
        midnight = Date().ignoreTimeComponents()
        timeService = MockTimeService()
        baseSlot = TemporaryTimeSlot(start: midnight, category: Category.commute)
        
        timeService.mockDate = midnight.addingTimeInterval(1000)
        
        pipe = CapMidnightPipe(timeService: timeService)
    }
    
    func testSlotsThatPassMidnightAreSplitAtMidnigtWhenEndTimeIsAvalable()
    {
        let initialData =
            [ TestData(startOffset: -1000, endOffset: -0180, teferi.Category.leisure),
              TestData(startOffset: -0180, endOffset: 0360, teferi.Category.work),
              TestData(startOffset: 0360, endOffset: 0540, teferi.Category.leisure) ].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: -1000, endOffset: -0180, teferi.Category.leisure),
              TestData(startOffset: -0180, endOffset: 0000, teferi.Category.work),
              TestData(startOffset: 0000, endOffset: 0360, teferi.Category.work),
              TestData(startOffset: 0360, endOffset: 0540, teferi.Category.leisure) ].map(toTempTimeSlot)
        
        pipe.process(timeline: initialData)
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedTimeline[i]) }
    }
    
    func testSlotsThatPassMidnightAreSplitAtMidnigtWhenEndTimeIsNotAvalable()
    {
        let initialData =
            [ TestData(startOffset: -1000, endOffset: -0180, teferi.Category.leisure),
              TestData(startOffset: -0180, endOffset: nil, teferi.Category.work)].map(toTempTimeSlot)
        
        let expectedTimeline =
            [ TestData(startOffset: -1000, endOffset: -0180, teferi.Category.leisure),
              TestData(startOffset: -0180, endOffset: 0000, teferi.Category.work),
              TestData(startOffset: 0000, endOffset: nil, teferi.Category.work) ].map(toTempTimeSlot)
        
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
        return midnight.addingTimeInterval(timeInterval)
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
