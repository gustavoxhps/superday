import XCTest
import UserNotifications
import Nimble
import CoreLocation
@testable import teferi

class MergeShortSlotsPipeTests : XCTestCase
{
    private var pipe : MergeShortTimeSlotsPipe!
    
    override func setUp()
    {
        pipe = MergeShortTimeSlotsPipe()
    }
    
    func testIfAllSlotsAreBigItDoesNothing()
    {
        let timeline = [
            TemporaryTimeSlotBuilder(duration: 6 * 60),
            TemporaryTimeSlotBuilder(duration: 10 * 60),
            TemporaryTimeSlotBuilder(duration: 7 * 60),
            TemporaryTimeSlotBuilder(duration: 8 * 60),
            TemporaryTimeSlotBuilder(duration: 9 * 60)
        ].buildTimeline()
        
        let newTimeline = pipe.process(timeline: timeline)
        
        expect(newTimeline.count).to(equal(timeline.count))
    }
    
    func testIfOneSlotIsShortItMergesIt()
    {
        let timeline = [
            TemporaryTimeSlotBuilder(duration: 6 * 60),
            TemporaryTimeSlotBuilder(duration: 3 * 60),
            TemporaryTimeSlotBuilder(duration: 7 * 60),
            TemporaryTimeSlotBuilder(duration: 8 * 60),
            TemporaryTimeSlotBuilder(duration: 9 * 60)
            ].buildTimeline()
        
        let newTimeline = pipe.process(timeline: timeline)
        let oldTimelineDuration = timeline.map({ $0.duration ?? 0}).reduce(0, +)
        let newTimelineDuration = newTimeline.map({ $0.duration ?? 0}).reduce(0, +)

        expect(newTimeline.count).to(equal(timeline.count - 1))
        expect(newTimelineDuration).to(equal(oldTimelineDuration))
    }
    
    func testIfAllSlotsArShortItLeavesOne()
    {
        let timeline = [
            TemporaryTimeSlotBuilder(duration: 1 * 60),
            TemporaryTimeSlotBuilder(duration: 3 * 60),
            ].buildTimeline()
        
        let newTimeline = pipe.process(timeline: timeline)
        let oldTimelineDuration = timeline.map({ $0.duration ?? 0}).reduce(0, +)
        let newTimelineDuration = newTimeline.map({ $0.duration ?? 0}).reduce(0, +)
        
        expect(newTimeline.count).to(equal(1))
        expect(newTimelineDuration).to(equal(oldTimelineDuration))
    }
    
    func testIfTheLastSlotIsShortItKeepsItButDeletesOtherShortTimeSlots()
    {
        let timeline = [
            TemporaryTimeSlotBuilder(duration: 6 * 60),
            TemporaryTimeSlotBuilder(duration: 3 * 60),
            TemporaryTimeSlotBuilder(duration: 7 * 60),
            TemporaryTimeSlotBuilder(duration: 8 * 60),
            TemporaryTimeSlotBuilder(duration: 2 * 60)
            ].buildTimeline()
        
        let newTimeline = pipe.process(timeline: timeline)
        let oldTimelineDuration = timeline.map({ $0.duration ?? 0}).reduce(0, +)
        let newTimelineDuration = newTimeline.map({ $0.duration ?? 0}).reduce(0, +)
        
        expect(newTimeline.count).to(equal(timeline.count - 1))
        expect(newTimelineDuration).to(equal(oldTimelineDuration))
    }
    
    func testIfMoreThanOneSlotIsShortItMergesThemAll()
    {
        let timeline = [
            TemporaryTimeSlotBuilder(duration: 6 * 60),
            TemporaryTimeSlotBuilder(duration: 3 * 60),
            TemporaryTimeSlotBuilder(duration: 7 * 60),
            TemporaryTimeSlotBuilder(duration: 8 * 60),
            TemporaryTimeSlotBuilder(duration: 2 * 60),
            TemporaryTimeSlotBuilder(duration: 29 * 60)
            ].buildTimeline()
        
        let newTimeline = pipe.process(timeline: timeline)
        let oldTimelineDuration = timeline.map({ $0.duration ?? 0}).reduce(0, +)
        let newTimelineDuration = newTimeline.map({ $0.duration ?? 0}).reduce(0, +)

        expect(newTimeline.count).to(equal(timeline.count - 2))
        expect(newTimelineDuration).to(equal(oldTimelineDuration))
    }
    
    func testIfTimeSlotsAreNonConsecutiveItJustDeletesTheShortOne()
    {
        let now = Date()
        
        let timeline1 = [
            TemporaryTimeSlotBuilder(duration: 6 * 60),
            TemporaryTimeSlotBuilder(duration: 7 * 60),
            TemporaryTimeSlotBuilder(duration: 3 * 60)
            ].buildTimeline(withStartTime: now)
        
        let timeline2 = [
            TemporaryTimeSlotBuilder(duration: 8 * 60),
            TemporaryTimeSlotBuilder(duration: 9 * 60),
            TemporaryTimeSlotBuilder(duration: 10 * 60)
            ].buildTimeline(withStartTime: now.addingTimeInterval(24*60*60))
        
        let timeline = timeline1 + timeline2
        
        let newTimeline = pipe.process(timeline: timeline)
        let oldTimelineDuration = timeline.map({ $0.duration ?? 0}).reduce(0, +)
        let newTimelineDuration = newTimeline.map({ $0.duration ?? 0}).reduce(0, +)
        
        expect(newTimeline.count).to(equal(timeline.count - 1))
        expect(newTimelineDuration).to(equal(oldTimelineDuration))
        expect(newTimeline[1].duration).to(equal(10*60))
    }
    
    func testITDeletesShortTimeslotsBeforeTheGap()
    {
        let now = Date()
        
        let timeline1 = [
            TemporaryTimeSlotBuilder(duration: 3 * 60),
            TemporaryTimeSlotBuilder(duration: 1 * 60)
            ].buildTimeline(withStartTime: now)
        
        let timeline2 = [
            TemporaryTimeSlotBuilder(duration: 8 * 60),
            TemporaryTimeSlotBuilder(duration: 9 * 60),
            TemporaryTimeSlotBuilder(duration: 10 * 60)
            ].buildTimeline(withStartTime: now.addingTimeInterval(24*60*60))
        
        let timeline = timeline1 + timeline2
        
        let newTimeline = pipe.process(timeline: timeline)
        let oldTimelineDuration = timeline.map({ $0.duration ?? 0}).reduce(0, +)
        let newTimelineDuration = newTimeline.map({ $0.duration ?? 0}).reduce(0, +)
        
        expect(newTimeline.count).to(equal(timeline.count-2))
        expect(newTimelineDuration).to(equal(oldTimelineDuration - 4 * 60))
    }
    
    
    func testChoosesSlotWithSmartGuessWhenMerging()
    {
        let timeline = [
            TemporaryTimeSlotBuilder(duration: 6 * 60),
            TemporaryTimeSlotBuilder(duration: 3 * 60, smartGuess:smartGuess(withCategory: .family)),
            TemporaryTimeSlotBuilder(duration: 7 * 60),
            TemporaryTimeSlotBuilder(duration: 8 * 60),
            TemporaryTimeSlotBuilder(duration: 9 * 60)
            ].buildTimeline()
        
        let newTimeline = pipe.process(timeline: timeline)
        let newCategories:[teferi.Category] = [.unknown, .family, .unknown, .unknown]
        let oldTimelineDuration = timeline.map({ $0.duration ?? 0}).reduce(0, +)
        let newTimelineDuration = newTimeline.map({ $0.duration ?? 0}).reduce(0, +)
        
        expect(newTimeline.map{ $0.category }).to(equal(newCategories))
        expect(newTimelineDuration).to(equal(oldTimelineDuration))
    }
    
    func testChoosesSlotWithSmartGuessIfItsNotTheShortWhenMerging()
    {
        let timeline = [
            TemporaryTimeSlotBuilder(duration: 6 * 60),
            TemporaryTimeSlotBuilder(duration: 3 * 60),
            TemporaryTimeSlotBuilder(duration: 7 * 60, smartGuess:smartGuess(withCategory: .family)),
            TemporaryTimeSlotBuilder(duration: 8 * 60),
            TemporaryTimeSlotBuilder(duration: 9 * 60)
            ].buildTimeline()
        
        let newTimeline = pipe.process(timeline: timeline)
        let newCategories:[teferi.Category] = [.unknown, .family, .unknown, .unknown]
        let oldTimelineDuration = timeline.map({ $0.duration ?? 0}).reduce(0, +)
        let newTimelineDuration = newTimeline.map({ $0.duration ?? 0}).reduce(0, +)
        
        expect(newTimeline.map{ $0.category }).to(equal(newCategories))
        expect(newTimelineDuration).to(equal(oldTimelineDuration))
    }
    
    func testIfBothHaveSmartGuessesTakesTheOneWithLocation()
    {
        let location = Location(fromCLLocation: CLLocation.baseLocation)
        
        let timeline = [
            TemporaryTimeSlotBuilder(duration: 6 * 60),
            TemporaryTimeSlotBuilder(duration: 3 * 60, smartGuess:smartGuess(withCategory: .food), location: location),
            TemporaryTimeSlotBuilder(duration: 7 * 60, smartGuess:smartGuess(withCategory: .family)),
            TemporaryTimeSlotBuilder(duration: 8 * 60),
            TemporaryTimeSlotBuilder(duration: 9 * 60)
            ].buildTimeline()
        
        let newTimeline = pipe.process(timeline: timeline)
        let newCategories:[teferi.Category] = [.unknown, .food, .unknown, .unknown]
        let oldTimelineDuration = timeline.map({ $0.duration ?? 0}).reduce(0, +)
        let newTimelineDuration = newTimeline.map({ $0.duration ?? 0}).reduce(0, +)
        
        expect(newTimeline.map{ $0.category }).to(equal(newCategories))
        expect(newTimelineDuration).to(equal(oldTimelineDuration))
    }
    
    func testIfBothHaveSmartGuessAndLocationTakeTheMostAccurateOne()
    {
        let lessAccurateLocation = Location(fromCLLocation:CLLocation.baseLocation.with(accuracy: 100))
        let moreAccurateLocation = Location(fromCLLocation:CLLocation.baseLocation.with(accuracy: 20))
        
        let timeline = [
            TemporaryTimeSlotBuilder(duration: 6 * 60),
            TemporaryTimeSlotBuilder(duration: 3 * 60, smartGuess:smartGuess(withCategory: .food), location: lessAccurateLocation),
            TemporaryTimeSlotBuilder(duration: 7 * 60, smartGuess:smartGuess(withCategory: .work), location: moreAccurateLocation),
            TemporaryTimeSlotBuilder(duration: 8 * 60),
            TemporaryTimeSlotBuilder(duration: 9 * 60)
            ].buildTimeline()
        
        let newTimeline = pipe.process(timeline: timeline)
        let newCategories:[teferi.Category] = [.unknown, .work, .unknown, .unknown]
        let oldTimelineDuration = timeline.map({ $0.duration ?? 0}).reduce(0, +)
        let newTimelineDuration = newTimeline.map({ $0.duration ?? 0}).reduce(0, +)
        
        expect(newTimeline.map{ $0.category }).to(equal(newCategories))
        expect(newTimelineDuration).to(equal(oldTimelineDuration))
    }
    
    func testIfBothHaveLocationTakeTheMostAccurateOne()
    {
        let lessAccurateLocation = Location(fromCLLocation:CLLocation.baseLocation.with(accuracy: 100))
        let moreAccurateLocation = Location(fromCLLocation:CLLocation.baseLocation.with(accuracy: 20))
        
        let timeline = [
            TemporaryTimeSlotBuilder(duration: 6 * 60),
            TemporaryTimeSlotBuilder(duration: 3 * 60, category: .leisure, location: lessAccurateLocation),
            TemporaryTimeSlotBuilder(duration: 7 * 60, category: .fitness, location: moreAccurateLocation),
            TemporaryTimeSlotBuilder(duration: 8 * 60),
            TemporaryTimeSlotBuilder(duration: 9 * 60)
            ].buildTimeline()
        
        let newTimeline = pipe.process(timeline: timeline)
        let newCategories:[teferi.Category] = [.unknown, .fitness, .unknown, .unknown]
        let oldTimelineDuration = timeline.map({ $0.duration ?? 0}).reduce(0, +)
        let newTimelineDuration = newTimeline.map({ $0.duration ?? 0}).reduce(0, +)
        
        expect(newTimeline.map{ $0.category }).to(equal(newCategories))
        expect(newTimelineDuration).to(equal(oldTimelineDuration))
    }
    
    private func smartGuess(withCategory category: teferi.Category) -> SmartGuess
    {
        return SmartGuess(
            withId: 0,
            category: category,
            location: CLLocation.baseLocation,
            lastUsed: Date())
    }
}


fileprivate struct TemporaryTimeSlotBuilder
{
    let duration: TimeInterval
    let category: teferi.Category
    let smartGuess: SmartGuess?
    let location: Location?
    
    init(duration: TimeInterval, category: teferi.Category = .unknown, smartGuess: SmartGuess? = nil, location: Location? = nil)
    {
        self.duration = duration
        self.category = category
        self.smartGuess = smartGuess
        self.location = location
    }
}

fileprivate extension Array where Element == TemporaryTimeSlotBuilder
{
    func buildTimeline(withStartTime start:Date = Date()) -> [TemporaryTimeSlot]
    {
        return self.reduce([TemporaryTimeSlot](), { acc, ts in
          
            guard acc.count > 0 else
            {
                return [
                    TemporaryTimeSlot.create(withStart : start, end: start.addingTimeInterval(ts.duration), smartGuess: ts.smartGuess, category: ts.category, location: ts.location)
                ]
            }
            
            let accDuration = acc.map{ $0.duration ?? 0}.reduce(0, +)
            let newStart = start.addingTimeInterval(accDuration)
            
            return acc + [
                TemporaryTimeSlot.create(withStart : newStart, end: newStart.addingTimeInterval(ts.duration), smartGuess: ts.smartGuess, category: ts.category, location: ts.location)
            ]
            
        })
    }
}

fileprivate extension TemporaryTimeSlot
{
    static func create(withStart startTime: Date, end endTime: Date, smartGuess: SmartGuess?, category: teferi.Category?, location:Location?) -> TemporaryTimeSlot
    {
        var _category: teferi.Category? = nil
        if let _smartGuess = smartGuess
        {
            _category = _smartGuess.category
        }
        else
        {
            _category = category
        }
        
        return TemporaryTimeSlot(
            start: startTime,
            end: endTime,
            smartGuess: smartGuess,
            category: _category ?? .unknown,
            location: location
            )
    }
}

