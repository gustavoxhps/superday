import UIKit

@IBDesignable
class DailySummaryPieChartActivity: UIView
{
    var dailyActivities : [Activity]?
    {
        didSet
        {
            self.setNeedsDisplay()
        }
    }
    
    override func prepareForInterfaceBuilder()
    {
        super.prepareForInterfaceBuilder()
        dailyActivities = [Activity(category: .food, duration: 500),
                           Activity(category: .work, duration: 1000),
                           Activity(category: .commute, duration: 300),
                           Activity(category: .unknown, duration: 500),
                           Activity(category: .family, duration: 500),
                           Activity(category: .friends, duration: 500)]
    }
    
    override func draw(_ rect: CGRect)
    {
        guard let activities = self.dailyActivities, activities.count > 0 else { return }
        
        // This non-generic function dramatically improves compilation times of complex expressions.
        func fastFloor(_ x: CGFloat) -> CGFloat { return floor(x) }
        
        let totalTimeSpent = activities.totalDurations
        let anglePerSec = CGFloat( 360.0 / totalTimeSpent )
        
        var startAngle = -90 * CGFloat.pi/180
        
        for activity in activities
        {
            let endAngle = startAngle + CGFloat(activity.duration) * anglePerSec * CGFloat.pi/180
            
            let piePiecePath = UIBezierPath()
            piePiecePath.addArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            piePiecePath.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
            piePiecePath.close()
            
            activity.category.color.setFill()
            piePiecePath.fill()
            startAngle = endAngle
        }
        
        
        //// centerCircle Drawing
        let centerCirclePath = UIBezierPath(ovalIn: CGRect(x: rect.minX + fastFloor(rect.width * 0.31395 + 0.5), y: rect.minY + fastFloor(rect.height * 0.31395 + 0.5), width: fastFloor(rect.width * 0.68605 + 0.5) - fastFloor(rect.width * 0.31395 + 0.5), height: fastFloor(rect.height * 0.68605 + 0.5) - fastFloor(rect.height * 0.31395 + 0.5)))
        let centerColor = backgroundColor == .clear && backgroundColor != nil ? .white : backgroundColor!
        centerColor.setFill()
        centerCirclePath.fill()
    }
}
