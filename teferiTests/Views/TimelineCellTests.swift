import Foundation
import XCTest
import Nimble
@testable import teferi

class TimelineCellTests : XCTestCase
{
    // MARK: Fields
    private var timeSlot : TimeSlot!
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
        
        timeSlot = TimeSlot(withStartTime: timeService.now,
                                 category: .work,
                                 categoryWasSetByUser: false)
        
        let duration = timeSlotService.calculateDuration(ofTimeSlot: timeSlot)
        timelineItem = TimelineItem(timeSlot: timeSlot,
                                         durations: [ duration ],
                                         lastInPastDay: false,
                                         shouldDisplayCategoryName: true)

        view = Bundle.main.loadNibNamed("TimelineCell", owner: nil, options: nil)?.first! as! TimelineCell
        view.bind(toTimelineItem: timelineItem, index: 0, duration: duration)
    }
        
    func testTheImageChangesAccordingToTheBoundTimeSlot()
    {
        expect(self.view.categoryIcon.image).toNot(beNil())
    }
    
    func testTheDescriptionChangesAccordingToTheBoundTimeSlot()
    {
        expect(self.view.slotDescription.text).to(equal(timelineItem.timeSlot.category.description))
    }
    
    func testTheTimeChangesAccordingToTheBoundTimeSlot()
    {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let dateString = formatter.string(from: timelineItem.timeSlot.startTime)
        
        expect(self.view.slotTime.text).to(equal(dateString))
    }
    
    func testTheTimeDescriptionShowsEndDateIfIsLastPastTimeSlot()
    {
        let date = Date().yesterday.ignoreTimeComponents()
        var newTimeSlot = createTimeSlot(withStartTime: date).withEndDate(date.addingTimeInterval(5000))
        let duration = timeSlotService.calculateDuration(ofTimeSlot: newTimeSlot)
        let newTimelineItem = TimelineItem(timeSlot: newTimeSlot,
                                           durations: [duration],
                                            lastInPastDay: true,
                                            shouldDisplayCategoryName: true)
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        view.bind(toTimelineItem: newTimelineItem, index: 0, duration: duration)
        
        let startText = formatter.string(from: newTimeSlot.startTime)
        let endText = formatter.string(from: newTimeSlot.endTime!)
        
        let expectedText = "\(startText) - \(endText)"
        
        expect(self.view.slotTime.text).to(equal(expectedText))
    }
    
    func testTheDescriptionHasNoTextWhenTheCategoryIsUnknown()
    {
        let unknownTimeSlot = createTimeSlot(withStartTime: Date())
        let duration = timeSlotService.calculateDuration(ofTimeSlot: timeSlot)
        let unknownTimelineItem = TimelineItem(timeSlot: unknownTimeSlot,
                                               durations: [duration],
                                               lastInPastDay: false,
                                               shouldDisplayCategoryName: true)

        view.bind(toTimelineItem: unknownTimelineItem, index: 0, duration: duration)
        
        expect(self.view.slotDescription.text).to(equal(""))
    }
    
    func testTheElapsedTimeLabelShowsOnlyMinutesWhenLessThanAnHourHasPassed()
    {
        let minuteMask = "%02d min"
        let interval = Int(timeSlotService.calculateDuration(ofTimeSlot: timeSlot))
        let minutes = (interval / 60) % 60
        
        let expectedText = String(format: minuteMask, minutes)
        
        expect(self.view.elapsedTime.text).to(equal(expectedText))
    }
    
    func testTheElapsedTimeLabelShowsHoursAndMinutesWhenOverAnHourHasPassed()
    {
        let date = Date().yesterday.ignoreTimeComponents()
        timeService.mockDate = date.addingTimeInterval(5000)
        
        let newTimeSlot = createTimeSlot(withStartTime: date)
        let duration = timeSlotService.calculateDuration(ofTimeSlot: newTimeSlot)
        let newTimelineItem = TimelineItem(timeSlot: newTimeSlot,
                                           durations: [duration],
                                           lastInPastDay: false,
                                           shouldDisplayCategoryName: true)
        
        view.bind(toTimelineItem: newTimelineItem, index: 0, duration: duration)
        
        let hourMask = "%02d h %02d min"
        let interval = Int(timeSlotService.calculateDuration(ofTimeSlot: newTimeSlot))
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
        var newTimeSlot = createTimeSlot(withStartTime: date)
        newTimeSlot = newTimeSlot.withEndDate(Date())
        let duration = timeSlotService.calculateDuration(ofTimeSlot: newTimeSlot)
        let newTimelineItem = TimelineItem(timeSlot: newTimeSlot,
                                           durations: [duration],
                                           lastInPastDay: false,
                                           shouldDisplayCategoryName: true)

        view.bind(toTimelineItem: newTimelineItem, index: 0, duration: duration)
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
        let duration = timeSlotService.calculateDuration(ofTimeSlot: timeSlot)
        let newTimelineItem = TimelineItem(timeSlot: timelineItem.timeSlot,
                                           durations: [duration],
                                           lastInPastDay: false,
                                           shouldDisplayCategoryName: false)

        view.bind(toTimelineItem: newTimelineItem, index: 0, duration: duration)

        
        expect(self.view.slotDescription.text).to(equal(""))
    }
    
    private func createTimeSlot(withStartTime time: Date) -> TimeSlot
    {
        return TimeSlot(withStartTime: time,
                        category: .unknown,
                        categoryWasSetByUser: false)
    }
}
