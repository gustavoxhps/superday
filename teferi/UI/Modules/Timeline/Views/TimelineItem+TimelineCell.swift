import Foundation
import CoreGraphics

extension TimelineItem
{
    var lineHeight: CGFloat
    {
        if timeSlots.count > 1 {
            return 64
        }
        
        if category == .sleep {
            return 20.0
        } else {
            let newHeight = Constants.minLineHeight + Constants.timelineSlope * (CGFloat(duration) - Constants.minTimelineInterval)
            return max(min(newHeight, Constants.maxLineHeight), Constants.minLineHeight)
        }
    }
    
    var slotTimeText: String
    {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let startString = formatter.string(from: startTime)
        
        if isLastInPastDay, let endTime = endTime {
            let endString = formatter.string(from: endTime)
            return startString + " - " + endString
        } else {
            return startString
        }
    }
    
    var elapsedTimeText: String
    {
        let hourMask = "%02d h %02d min"
        let minuteMask = "%02d min"

        let minutes = (Int(duration) / 60) % 60
        let hours = (Int(duration) / 3600)
        
        return hours > 0 ? String(format: hourMask, hours, minutes) : String(format: minuteMask, minutes)
    }
    
    var slotDescriptionText: String
    {
        guard shouldDisplayCategoryName && category != .unknown else {
            return ""
        }

        return category.description
    }
}
