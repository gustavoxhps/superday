import Foundation
import UIKit

class CalendarDailyActivityView : UIView
{
    func reset()
    {
        self.layer.sublayers?.forEach { sublayer in sublayer.removeFromSuperlayer() }
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 1.0
        self.backgroundColor = UIColor.clear
    }
    
    func update(dailyActivity: [ Activity ]?)
    {
        self.reset()
        
        guard let activities = dailyActivity, activities.count > 0 else
        {
            self.backgroundColor = Color.lightGray
            return
        }
        
        self.backgroundColor = UIColor.clear
        
        let totalTimeSpent = activities.reduce(0.0, self.sumDuration)
        let availableWidth = Double(self.bounds.size.width - CGFloat(activities.count) + 1.0)
        
        var startingX = 0.0
        
        for activity in activities
        {
            let layerWidth = availableWidth * (activity.duration / totalTimeSpent)
            
            //Filters layers too small to be seen
            guard layerWidth > 1 else { continue }
            
            let layer = CALayer()
            layer.cornerRadius = 1
            layer.backgroundColor = activity.category.color.cgColor
            layer.frame = CGRect(x: startingX, y: 0, width: layerWidth, height: Double(self.frame.height))
            startingX += layerWidth + 1
            
            self.layer.addSublayer(layer)
        }
        
        self.layoutIfNeeded()
    }
    
    private func sumDuration(accumulator: Double, activity: Activity) -> TimeInterval
    {
        return accumulator + activity.duration
    }
}
