import Foundation

struct TimelineItem
{
    let timeSlots : [TimeSlot]
    let category: Category
    let duration : TimeInterval
    let shouldDisplayCategoryName : Bool
    let isLastInPastDay : Bool
    let isRunning: Bool
    
    var startTime: Date {
        return timeSlots.first!.startTime
    }
    
    var endTime: Date? {
        return timeSlots.last!.endTime
    }
}


extension TimelineItem
{
    func withLastTimeSlotFlag(isCurrentDay: Bool) -> TimelineItem
    {
        return TimelineItem(
            timeSlots: self.timeSlots,
            category: self.category,
            duration: self.duration,
            shouldDisplayCategoryName: self.shouldDisplayCategoryName,
            isLastInPastDay: !isCurrentDay,
            isRunning: isCurrentDay
        )
    }
}
