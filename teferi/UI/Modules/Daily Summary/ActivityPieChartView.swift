import UIKit

@IBDesignable
class ActivityPieChartView: UIView
{
    private var activities = [Activity]()
    {
        didSet
        {
            self.updateSlices()
        }
    }
    
    private var centerCircleRadius: CGFloat
    {
        return min(self.bounds.width, self.bounds.height) / 3
    }
    
    @IBInspectable var centerCircleColor: Color = .white
    {
        didSet
        {
            self.updateSlices()
        }
    }
    
    private let containerLayer: CALayer = {
        let container = CALayer()
        for category in Category.all
        {
            let slice = PieSliceLayer()
            slice.category = category
            container.addSublayer(slice)
        }
        return container
    }()
    
    private lazy var centerCircleLayer: CAShapeLayer = {
        let circleLayer = CAShapeLayer()
        circleLayer.fillColor = Color.white.cgColor
        return circleLayer
    }()
    
    private lazy var backgroundCircleLayer: CAShapeLayer = {
        let circleLayer = CAShapeLayer()
        circleLayer.fillColor = Color.init(white: 0.9, alpha: 1).cgColor
        return circleLayer
    }()
    
    func setActivities(_ activities: [Activity])
    {
        self.activities = activities
    }
    
    override func prepareForInterfaceBuilder()
    {
        super.prepareForInterfaceBuilder()
        activities = [Activity(category: .food, duration: 500),
                           Activity(category: .work, duration: 1000),
                           Activity(category: .commute, duration: 300),
                           Activity(category: .unknown, duration: 500),
                           Activity(category: .family, duration: 500),
                           Activity(category: .friends, duration: 500)]
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        let centerCircleOffset = CGPoint(x: (self.bounds.size.width - self.centerCircleRadius) / 2,
                             y: (self.bounds.size.height - self.centerCircleRadius) / 2);
        centerCircleLayer.path = UIBezierPath(ovalIn: CGRect(x: centerCircleOffset.x,
                                                             y: centerCircleOffset.y,
                                                             width: self.centerCircleRadius,
                                                             height: self.centerCircleRadius)).cgPath
        
        let maxLength = min(self.bounds.size.width, self.bounds.size.height)
        let backgroundCircleOffset = CGPoint(x: (self.bounds.size.width - maxLength) / 2,
                                         y: (self.bounds.size.height - maxLength) / 2);
        backgroundCircleLayer.path = UIBezierPath(ovalIn: CGRect(x: backgroundCircleOffset.x,
                                                                 y: backgroundCircleOffset.y,
                                                                 width: maxLength,
                                                                 height: maxLength)).cgPath
        
        updateSlices()
    }
    
    private func updateSlices()
    {
        layer.addSublayer(backgroundCircleLayer)
        
        var startAngle: CGFloat = -90 * CGFloat.pi/180
        containerLayer.frame = self.bounds
        layer.addSublayer(containerLayer)
        
        for (index, activity) in activities.enumerated()
        {
            let slice = (containerLayer.sublayers as! [PieSliceLayer]).filter({ $0.category == activity.category }).first!
            containerLayer.insertSublayer(slice, at: UInt32(index))
        }
        
        let totalTimeSpent = activities.totalDurations
        let anglePerSec = CGFloat( 360.0 / totalTimeSpent )
        for (index, slice) in (containerLayer.sublayers as! [PieSliceLayer]).enumerated()
        {
            slice.frame = bounds
            
            if index < activities.count
            {
                let activity = activities[index]
                let endAngle = startAngle + CGFloat(activity.duration) * anglePerSec * CGFloat.pi/180
                slice.startAngle = startAngle
                slice.endAngle = endAngle
                startAngle = endAngle
            }
            else
            {
                slice.startAngle = startAngle
                slice.endAngle = startAngle
            }
        }
        
        layer.addSublayer(centerCircleLayer)
    }
}
