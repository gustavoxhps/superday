import Foundation

struct TimelineItem
{
    let timeSlot : TimeSlot
    let durations : [ TimeInterval ]
    let lastInPastDay : Bool
    let shouldDisplayCategoryName : Bool
}


extension TimelineItem
{
    func withoutDurations() -> TimelineItem
    {
        return TimelineItem(
            timeSlot: self.timeSlot,
            durations: [],
            lastInPastDay: self.lastInPastDay,
            shouldDisplayCategoryName: self.shouldDisplayCategoryName
        )
    }
}
