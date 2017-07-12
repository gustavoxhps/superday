import Foundation
import XCTest
import Nimble
@testable import teferi

class TimelineCellTests : XCTestCase
{
    // MARK: Fields
    private var timelineItem : TimelineItem!
    
    private var timeService : MockTimeService!
    private var locationService : MockLocationService!
    private var timeSlotService : MockTimeSlotService!
    
    private var view : TimelineCell!
    
    override func setUp()
    {
        timeService = MockTimeService()
        locationService = MockLocationService()
        timeSlotService = MockTimeSlotService(timeService: timeService,
                                                   locationService: locationService)
        
        timelineItem = createTimelineItem(withStartTime: timeService.now, category: .work)

        view = Bundle.main.loadNibNamed("TimelineCell", owner: nil, options: nil)?.first! as! TimelineCell
        view.timelineItem = timelineItem
    }
        
    func testTheImageChangesAccordingToTheBoundTimeSlot()
    {
        expect(self.view.categoryIcon.image).toNot(beNil())
    }
    
    func testTheDescriptionChangesAccordingToTheBoundTimeSlot()
    {
        expect(self.view.slotDescription.text).to(equal(timelineItem.category.description))
    }
    
    func testTheTimeChangesAccordingToTheBoundTimeSlot()
    {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let dateString = formatter.string(from: timelineItem.startTime)
        
        expect(self.view.slotTime.text).to(equal(dateString))
    }
    
    func testTheTimeDescriptionShowsEndDateIfIsLastPastTimeSlot()
    {
        let date = Date().yesterday.ignoreTimeComponents()
        let newTimelineItem = createTimelineItem(withStartTime: date, endTime: date.addingTimeInterval(5000), isLastInPastDay: true)

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        view.timelineItem = newTimelineItem
        
        let startText = formatter.string(from: newTimelineItem.startTime)
        let endText = formatter.string(from: newTimelineItem.endTime!)
        
        let expectedText = "\(startText) - \(endText)"
        
        expect(self.view.slotTime.text).to(equal(expectedText))
    }
    
    func testTheDescriptionHasNoTextWhenTheCategoryIsUnknown()
    {
        let unknownTimelineItem = createTimelineItem(withStartTime: Date())

        view.timelineItem = unknownTimelineItem
        
        expect(self.view.slotDescription.text).to(equal(""))
    }
    
    func testTheElapsedTimeLabelShowsOnlyMinutesWhenLessThanAnHourHasPassed()
    {
        let minuteMask = "%02d min"
        let interval: TimeInterval = 2000
        let minutes = (Int(interval) / 60) % 60
        
        let expectedText = String(format: minuteMask, minutes)
        
        let now = Date()
        let newTimelineItem = createTimelineItem(withStartTime: now, endTime: now.addingTimeInterval(interval))
        view.timelineItem = newTimelineItem

        expect(self.view.elapsedTime.text).to(equal(expectedText))
    }
    
    func testTheElapsedTimeLabelShowsHoursAndMinutesWhenOverAnHourHasPassed()
    {
        let date = Date().yesterday.ignoreTimeComponents()
        timeService.mockDate = date.addingTimeInterval(5000)
        
        let newTimelineItem = createTimelineItem(withStartTime: date)
        
        view.timelineItem = newTimelineItem
        
        let hourMask = "%02d h %02d min"
        let interval = Int(timeSlotService.calculateDuration(ofTimeSlot: newTimelineItem.timeSlots.first!))
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        
        let expectedText = String(format: hourMask, hours, minutes)
        
        expect(self.view.elapsedTime.text).to(equal(expectedText))
    }
    
    func testTheElapsedTimeLabelColorChangesAccordingToTheBoundTimeSlot()
    {
        let expectedColor = Category.work.color
        let actualColor = view.elapsedTime.textColor
        
        expect(expectedColor).to(equal(actualColor))
    }
    
    func testTheTimelineCellLineHeightChangesAccordingToTheBoundTimeSlot()
    {
        let oldLineHeight = view.lineView.frame.height
        let date = Date().add(days: -1)
        let newTimelineItem = createTimelineItem(withStartTime: date, endTime: Date())

        view.timelineItem = newTimelineItem
        
        view.layoutIfNeeded()
        let newLineHeight = view.lineView.frame.height
        
        expect(oldLineHeight).to(beLessThan(newLineHeight))
    }
    
    func testTheLineColorChangesAccordingToTheBoundTimeSlot()
    {
        let expectedColor = Category.work.color
        let actualColor = view.lineView.color
        
        expect(expectedColor).to(equal(actualColor))
    }
    
    func testNoCategoryIsShownIfTheTimeSlotHasThePropertyShouldDisplayCategoryNameSetToFalse()
    {
        let timeSlot = TimeSlot(withStartTime: Date(),
                                endTime: Date().addingTimeInterval(2000),
                                category: .work,
                                categoryWasSetByUser: false)
        let duration = timeSlotService.calculateDuration(ofTimeSlot: timeSlot)

        let newTimelineItem = TimelineItem(
            timeSlots: [timeSlot],
            category: timeSlot.category,
            duration: duration,
            shouldDisplayCategoryName: false,
            isLastInPastDay: false,
            isRunning: false)


        view.timelineItem = newTimelineItem
        
        expect(self.view.slotDescription.text).to(equal(""))
    }
    
    private func createTimelineItem(withStartTime time: Date, endTime: Date? = nil, category: teferi.Category = .unknown, isLastInPastDay: Bool = false) -> TimelineItem
    {
        let timeSlot = TimeSlot(withStartTime: time,
                                endTime: endTime,
                                category: category,
                                categoryWasSetByUser: false)
        let duration = timeSlotService.calculateDuration(ofTimeSlot: timeSlot)

        return TimelineItem(
            timeSlots: [timeSlot],
            category: timeSlot.category,
            duration: duration,
            shouldDisplayCategoryName: true,
            isLastInPastDay: isLastInPastDay,
            isRunning: false)
    }
}
