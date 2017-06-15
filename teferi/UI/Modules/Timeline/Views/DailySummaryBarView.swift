import Foundation
import UIKit

class DailySummaryBarView : UIView
{
    private let barView = BarView()
    
    private var barHeight = CGFloat(10)
    private let minBarHeight = CGFloat(4)
    private let maxBarHeight = CGFloat(10)
    
    private var height = CGFloat(34)
    private let minHeight = CGFloat(24)
    private let maxHeight = CGFloat(34)
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        addSubview(barView)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createConstraints()
    {
        snp.makeConstraints { make in
            make.height.equalTo(maxHeight)
            make.top.left.right.equalToSuperview()
        }
        
        barView.snp.makeConstraints { make in
            make.height.equalTo(barHeight)
            make.centerX.centerY.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
    }
    
    func resize(by size: CGFloat)
    {
        let isGrowing = size > 0
        
        height = isGrowing
               ? max(minHeight, height - size)
               : min(maxHeight, height + abs(size))
        
        barHeight = isGrowing
               ? max(minBarHeight, barHeight - size)
               : min(maxBarHeight, barHeight + abs(size))
        
        
        setNeedsUpdateConstraints()
    }
    
    func reset()
    {
        barHeight = 10
        height = 34
        
        setNeedsUpdateConstraints()
    }
    
    override func updateConstraints()
    {
        snp.updateConstraints { make in
            make.height.equalTo(height)
        }

        barView.snp.updateConstraints { make in
            make.height.equalTo(barHeight)
        }

        super.updateConstraints()
    }
    
    func setActivities(activities:[Activity])
    {
        barView.activities = activities
    }
}

class BarView: UIView
{
    var activities: [Activity]?
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        clipsToBounds = true
        layer.cornerRadius = frame.height / 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
    }

    override func draw(_ rect: CGRect)
    {
        guard let ctx = UIGraphicsGetCurrentContext(),
            let activities = activities, activities.count > 0 else { return }
        
        let totalTimeSpent = activities.totalDurations
        let availableWidth = Double(rect.size.width)
        
        var startingX = 0.0
        let lastItem = activities.count - 1
        
        for (index, activity) in activities.enumerated()
        {
            let layerWidth = lastItem != index
                ? availableWidth * (activity.duration / totalTimeSpent)
                : availableWidth - startingX
            
            ctx.addRect(CGRect(x: startingX, y: 0, width: layerWidth, height: Double(rect.height)))
            activity.category.color.setFill()
            ctx.drawPath(using: .fill)
            
            startingX += layerWidth
        }
    }
}
