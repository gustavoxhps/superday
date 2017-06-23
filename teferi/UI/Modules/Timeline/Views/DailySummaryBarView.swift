import Foundation
import UIKit

class DailySummaryBarView : UIView
{
    private let barView = BarView()
    private let containerView = UIView()
    private let shadowView = UIView()
    
    private var barHeight = CGFloat(10)
    private let minBarHeight = CGFloat(4)
    private let maxBarHeight = CGFloat(10)
    
    private var height = CGFloat(34)
    private let minHeight = CGFloat(24)
    private let maxHeight = CGFloat(34)
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        clipsToBounds = false
        containerView.frame = frame
        containerView.backgroundColor = UIColor.white
        
        shadowView.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 0)
        shadowView.layer.shadowOpacity = 0.0
        shadowView.layer.shadowRadius = 4.0

        addSubview(shadowView)
        addSubview(containerView)
        containerView.addSubview(barView)
        
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.layer.shadowPath = UIBezierPath(rect: shadowView.bounds).cgPath
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return containerView.hitTest(point, with:event)
    }
    
    func resize(by newHeight: CGFloat)
    {
        guard newHeight != 0 else { return }
        
        let isGrowing = newHeight > 0
        
        height = isGrowing
               ? max(minHeight, height - newHeight)
               : min(maxHeight, height + abs(newHeight))
        
        barHeight = isGrowing
               ? max(minBarHeight, barHeight - newHeight)
               : min(maxBarHeight, barHeight + abs(newHeight))
                
        setNeedsUpdateConstraints()
    }
    
    func setShadowOpacity(opacity: Float)
    {
        shadowView.layer.removeAllAnimations()
        let anim = CABasicAnimation(keyPath: "shadowOpacity")
        anim.fromValue = shadowView.layer.shadowOpacity
        anim.toValue = opacity
        anim.duration = 0.3
        shadowView.layer.add(anim, forKey: "shadowOpacity")
        
        shadowView.layer.shadowOpacity = opacity
    }
    
    override func updateConstraints()
    {
        containerView.snp.updateConstraints { make in
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
        resetHeight()
    }
    
    private func createConstraints()
    {
        shadowView.snp.makeConstraints { make in
            make.edges.equalTo(containerView)
        }
        
        containerView.snp.makeConstraints { make in
            make.height.equalTo(maxHeight)
            make.top.left.right.equalToSuperview()
        }
        
        barView.snp.makeConstraints { make in
            make.height.equalTo(barHeight)
            make.centerX.centerY.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
    }
    
    private func resetHeight()
    {
        barHeight = 10
        height = 34

        containerView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        
        barView.snp.updateConstraints { make in
            make.height.equalTo(barHeight)
        }
        
        UIView.animate({
            self.layoutIfNeeded()
        }, duration: 0.15)
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
