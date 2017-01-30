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
    private var timeSlotService : MockTimeSlotService!
    
    private var view : TimelineCell!
    
    private var imageIcon : UIImageView
    {
        let view = self.view.subviews.filter { v in v is UIImageView  }.first!
        return view as! UIImageView
    }
    
    private var slotDescription : UILabel
    {
        let view = self.view.subviews.filter { v in v is UILabel  }.first!
        return view as! UILabel
    }
    
    private var slotTime : UILabel
    {
        let view = self.view.subviews.filter { v in v is UILabel  }.last!
        return view as! UILabel
    }
    
    private var timeLabel : UILabel
    {
        let labels = self.view.subviews.filter { v in v is UILabel  }
        
        let view = labels[labels.count - 2]
        return view as! UILabel
    }
    
    private var line : UIView
    {
        return  self.view.subviews.first!
    }
    
    override func setUp()
    {
        self.timeService = MockTimeService()
        self.timeSlotService = MockTimeSlotService(timeService: self.timeService)
        
        self.timeSlot = TimeSlot(withStartTime: self.timeService.now, category: .work, categoryWasSetByUser: false)
        let duration = self.timeSlotService.calculateDuration(ofTimeSlot: timeSlot)
        self.timelineItem = TimelineItem(timeSlot: self.timeSlot,
                                         durations: [ duration ],
                                         lastInPastDay: false,
                                         shouldDisplayCategoryName: true)

        self.view = Bundle.main.loadNibNamed("TimelineCell", owner: nil, options: nil)?.first! as! TimelineCell
        self.view.bind(toTimelineItem: timelineItem, index: 0, duration: duration)
    }
    
    override func tearDown()
    {
        self.timelineItem.timeSlot.category = .work
    }
    
    func testTheImageChangesAccordingToTheBoundTimeSlot()
    {
        expect(self.imageIcon.image).toNot(beNil())
    }
    
    func testTheDescriptionChangesAccordingToTheBoundTimeSlot()
    {
        expect(self.slotDescription.text).to(equal(self.timelineItem.timeSlot.category.name))
    }
    
    func testTheTimeChangesAccordingToTheBoundTimeSlot()
    {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let dateString = formatter.string(from: self.timelineItem.timeSlot.startTime)
        
        expect(self.slotTime.text).to(equal(dateString))
    }
    
    func testTheTimeDescriptionShowsEndDateIfIsLastPastTimeSlot()
    {
        let date = Date().yesterday.ignoreTimeComponents()
        let newTimeSlot = self.createTimeSlot(withStartTime: date)
        let duration = self.timeSlotService.calculateDuration(ofTimeSlot: timeSlot)
        let newTimelineItem = TimelineItem(timeSlot: newTimeSlot,
                                           durations: [duration],
                                            lastInPastDay: true,
                                            shouldDisplayCategoryName: true)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        newTimeSlot.endTime = date.addingTimeInterval(5000)
       
        self.view.bind(toTimelineItem: newTimelineItem, index: 0, duration: duration)
        
        let startText = formatter.string(from: newTimeSlot.startTime)
        let endText = formatter.string(from: newTimeSlot.endTime!)
        
        let expectedText = "\(startText) - \(endText)"
        
        expect(self.slotTime.text).to(equal(expectedText))
    }
    
    func testTheDescriptionHasNoTextWhenTheCategoryIsUnknown()
    {
        let unknownTimeSlot = self.createTimeSlot(withStartTime: Date())
        let duration = self.timeSlotService.calculateDuration(ofTimeSlot: timeSlot)
        let unknownTimelineItem = TimelineItem(timeSlot: unknownTimeSlot,
                                               durations: [duration],
                                               lastInPastDay: false,
                                               shouldDisplayCategoryName: true)

        view.bind(toTimelineItem: unknownTimelineItem, index: 0, duration: duration)
        
        expect(self.slotDescription.text).to(equal(""))
    }
    
    func testTheElapsedTimeLabelShowsOnlyMinutesWhenLessThanAnHourHasPassed()
    {
        let minuteMask = "%02d min"
        let interval = Int(self.timeSlotService.calculateDuration(ofTimeSlot: timeSlot))
        let minutes = (interval / 60) % 60
        
        let expectedText = String(format: minuteMask, minutes)
        
        expect(self.timeLabel.text).to(equal(expectedText))
    }
    
    func testTheElapsedTimeLabelShowsHoursAndMinutesWhenOverAnHourHasPassed()
    {
        let date = Date().yesterday.ignoreTimeComponents()
        self.timeService.mockDate = date.addingTimeInterval(5000)
        
        let newTimeSlot = self.createTimeSlot(withStartTime: date)
        let duration = self.timeSlotService.calculateDuration(ofTimeSlot: newTimeSlot)
        let newTimelineItem = TimelineItem(timeSlot: newTimeSlot,
                                           durations: [duration],
                                           lastInPastDay: false,
                                           shouldDisplayCategoryName: true)
        
        self.view.bind(toTimelineItem: newTimelineItem, index: 0, duration: duration)
        
        let hourMask = "%02d h %02d min"
        let interval = Int(self.timeSlotService.calculateDuration(ofTimeSlot: newTimeSlot))
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        
        let expectedText = String(format: hourMask, hours, minutes)
        
        expect(self.timeLabel.text).to(equal(expectedText))
    }
    
    func testTheElapsedTimeLabelColorChangesAccordingToTheBoundTimeSlot()
    {
        let expectedColor = Category.work.color
        let actualColor = timeLabel.textColor!
        
        expect(expectedColor).to(equal(actualColor))
    }
    
    func testTheTimelineCellLineHeightChangesAccordingToTheBoundTimeSlot()
    {
        let oldLineHeight = self.line.frame.height
        let date = Date().add(days: -1)
        let newTimeSlot = self.createTimeSlot(withStartTime: date)
        newTimeSlot.endTime = Date()
        let duration = self.timeSlotService.calculateDuration(ofTimeSlot: newTimeSlot)
        let newTimelineItem = TimelineItem(timeSlot: newTimeSlot,
                                           durations: [duration],
                                           lastInPastDay: false,
                                           shouldDisplayCategoryName: true)

        self.view.bind(toTimelineItem: newTimelineItem, index: 0, duration: duration)
        self.view.layoutIfNeeded()
        let newLineHeight = line.frame.height
        
        expect(oldLineHeight).to(beLessThan(newLineHeight))
    }
    
    func testTheLineColorChangesAccordingToTheBoundTimeSlot()
    {
        let expectedColor = Category.work.color
        let actualColor = self.line.backgroundColor!
        
        expect(expectedColor).to(equal(actualColor))
    }
    
    func testNoCategoryIsShownIfTheTimeSlotHasThePropertyShouldDisplayCategoryNameSetToFalse()
    {
        let duration = self.timeSlotService.calculateDuration(ofTimeSlot: timeSlot)
        let newTimelineItem = TimelineItem(timeSlot: self.timelineItem.timeSlot,
                                           durations: [duration],
                                           lastInPastDay: false,
                                           shouldDisplayCategoryName: false)

        self.view.bind(toTimelineItem: newTimelineItem, index: 0, duration: duration)

        
        expect(self.slotDescription.text).to(equal(""))
    }
    
    private func createTimeSlot(withStartTime time: Date) -> TimeSlot
    {
        return TimeSlot(withStartTime: time, categoryWasSetByUser: false)
    }
}
