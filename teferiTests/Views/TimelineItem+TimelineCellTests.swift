import Foundation
import XCTest
import Nimble
@testable import teferi

class TimelineItem_TimelineCellTests: XCTestCase
{
    func testTheTimelineCellLineHeightIsHigherForLongerItems()
    {
        let now = Date()
        
        var timeslots = [
            TimeSlot(withStartTime: now, category: .work, categoryWasSetByUser: false),
        ]
        let item1 = TimelineItem(withTimeSlots: timeslots, category: Category.work, duration: 15 * 60)
        
        timeslots = [
            TimeSlot(withStartTime: now, category: .work, categoryWasSetByUser: false),
        ]
        let item2 = TimelineItem(withTimeSlots: timeslots, category: Category.work, duration: 30 * 60)
        
        expect(item1.lineHeight).to(beLessThan(item2.lineHeight))
    }
    
    func testGroupedTimelineItemsAlwaysHaveTheSameHeightRegardlessOfTotalDuration()
    {
        let now = Date()
        
        var timeslots = [
            TimeSlot(withStartTime: now, category: .work, categoryWasSetByUser: false),
            TimeSlot(withStartTime: now.addingTimeInterval(15*60), category: .work, categoryWasSetByUser: false)
        ]
        let item1 = TimelineItem(withTimeSlots: timeslots, category: Category.work, duration: 15*60)
        
        timeslots = [
            TimeSlot(withStartTime: now, category: .work, categoryWasSetByUser: false),
            TimeSlot(withStartTime: now.addingTimeInterval(30*60), category: .work, categoryWasSetByUser: false)
        ]
        let item2 = TimelineItem(withTimeSlots: timeslots, category: Category.work, duration: 30*60)
        
        expect(item1.lineHeight).to(equal(item2.lineHeight))
    }
    
    func testTimeSlotTextMatchesStartTime()
    {
        let startTime = Date()
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let expected = formatter.string(from: startTime)
        
        let timeslots = [
            TimeSlot(withStartTime: startTime, category: .work, categoryWasSetByUser: false),
        ]
        let item = TimelineItem(withTimeSlots: timeslots, category: Category.work, duration: 15*60)
        
        expect(item.slotTimeText).to(equal(expected))
    }
    
    func testTimeSlotTextMatchesStartAndEndTimeForLastSlotInLastDay()
    {
        let startTime = Date().yesterday.ignoreTimeComponents()
        let endTime = startTime.addingTimeInterval(2*60*60)
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let startText = formatter.string(from: startTime)
        let endText = formatter.string(from: endTime)
        let expectedText = "\(startText) - \(endText)"
        
        let timeslots = [
            TimeSlot(withStartTime: startTime, category: .work, categoryWasSetByUser: false).withEndDate(endTime),
        ]
        let item = TimelineItem(withTimeSlots: timeslots, category: Category.work, duration: 15*60, isLastInPastDay: true)
        
        expect(item.slotTimeText).to(equal(expectedText))
    }
    
    func testTheElapsedTimeLabelShowsOnlyMinutesWhenLessThanAnHourHasPassed()
    {
        let startTime = Date()
        let duration: TimeInterval = 2000

        let minuteMask = "%02d min"
        let minutes = (Int(duration) / 60) % 60
        let expectedText = String(format: minuteMask, minutes)
        
        let timeslots = [
            TimeSlot(withStartTime: startTime, category: .work, categoryWasSetByUser: false),
            ]
        let item = TimelineItem(withTimeSlots: timeslots, category: Category.work, duration: duration)
        
        expect(item.elapsedTimeText).to(equal(expectedText))
    }
    
    func testTheElapsedTimeLabelShowsHoursAndMinutesWhenOverAnHourHasPassed()
    {
        let startTime = Date()
        let duration: TimeInterval = 5000
        
        let hourMask = "%02d h %02d min"
        let minutes = (Int(duration) / 60) % 60
        let hours = (Int(duration) / 3600)
        let expectedText = String(format: hourMask, hours, minutes)
        
        let timeslots = [
            TimeSlot(withStartTime: startTime, category: .work, categoryWasSetByUser: false),
            ]
        let item = TimelineItem(withTimeSlots: timeslots, category: Category.work, duration: duration)
        
        expect(item.elapsedTimeText).to(equal(expectedText))
    }
    
    func testTheDescriptionMatchesTheBoundTimeSlot()
    {
        let startTime = Date()
        
        let timeslots = [
            TimeSlot(withStartTime: startTime, category: .work, categoryWasSetByUser: false),
            ]
        let item = TimelineItem(withTimeSlots: timeslots, category: Category.work, duration: 15*60, shouldDisplayCategoryName: true)
        
        expect(item.slotDescriptionText).to(equal(item.category.description))
    }
    
    func testTheDescriptionHasNoTextWhenTheCategoryIsUnknown()
    {
        let startTime = Date()
        
        let timeslots = [
            TimeSlot(withStartTime: startTime, category: .unknown, categoryWasSetByUser: false),
            ]
        let item = TimelineItem(withTimeSlots: timeslots, category: Category.unknown, duration: 15*60, shouldDisplayCategoryName: true)
        
        expect(item.slotDescriptionText).to(equal(""))
    }
    
    func testNoCategoryIsShownIfTheTimeSlotHasThePropertyShouldDisplayCategoryNameSetToFalse()
    {
        let startTime = Date()
        
        let timeslots = [
            TimeSlot(withStartTime: startTime, category: .unknown, categoryWasSetByUser: false),
            ]
        let item = TimelineItem(withTimeSlots: timeslots, category: Category.unknown, duration: 15*60, shouldDisplayCategoryName: false)
        
        expect(item.slotDescriptionText).to(equal(""))
    }
}
