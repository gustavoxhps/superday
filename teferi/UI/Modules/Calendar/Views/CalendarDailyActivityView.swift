import Foundation
import UIKit

class CalendarDailyActivityView : UIView
{
    func reset()
    {
        layer.sublayers?.forEach { sublayer in sublayer.removeFromSuperlayer() }
        
        clipsToBounds = true
        layer.cornerRadius = 1.0
        backgroundColor = UIColor.clear
    }
    
    func update(dailyActivity: [ Activity ]?)
    {
        reset()
        
        guard let activities = dailyActivity, activities.count > 0 else
        {
            backgroundColor = Style.Color.calendarNoData
            return
        }
        
        backgroundColor = UIColor.clear
        
        let totalTimeSpent = activities.totalDurations
        let availableWidth = Double(bounds.size.width - CGFloat(activities.count) + 1.0)
        
        var startingX = 0.0
        
        for activity in activities
        {
            let layerWidth = availableWidth * (activity.duration / totalTimeSpent)
            
            //Filters layers too small to be seen
            guard layerWidth > 1 else { continue }
            
            let activityLayer = CALayer()
            activityLayer.cornerRadius = 1
            activityLayer.backgroundColor = activity.category.color.cgColor
            activityLayer.frame = CGRect(x: startingX, y: 0, width: layerWidth, height: Double(frame.height))
            startingX += layerWidth + 1
            
            layer.addSublayer(activityLayer)
        }
        
        layoutIfNeeded()
    }
}
