import Foundation
import UIKit

enum DailySummaryBarAnimationDirection
{
    case left
    case right
}

class DailySummaryBarView : UIView
{
    var animationDirection: DailySummaryBarAnimationDirection? = nil

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
        barView.setActivities(activities, animationDirection: animationDirection)
        resetHeight()
        animationDirection = nil
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
    private var displayLink: CADisplayLink? = nil
    private var offset: Double = 0
    private var nextOffset: Double = 0

    private var activities: [Activity]? {
        didSet {
            old_activities = oldValue
        }
    }
    private var old_activities: [Activity]?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = Style.Color.lightGray
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
    
    func setActivities(_ activities: [Activity], animationDirection: DailySummaryBarAnimationDirection?)
    {
        self.activities = activities
        
        guard let direction = animationDirection else {
            self.setNeedsDisplay()
            return
        }
        
        animateTransition(direction)
    }

    override func draw(_ rect: CGRect)
    {
        guard let activities = activities, activities.count > 0 else { return }
        
        if old_activities != nil
        {
            drawActivities(activitiesToDraw: old_activities!, rect: rect, start: 0)
        }
        
        drawActivities(activitiesToDraw: activities, rect: rect, start: offset)
    }
    
    private func drawActivities(activitiesToDraw: [Activity], rect: CGRect, start:Double)
    {
        guard let ctx = UIGraphicsGetCurrentContext(), activitiesToDraw.count > 0 else { return }

        let totalTimeSpent = activitiesToDraw.totalDurations
        let availableWidth = Double(rect.size.width)

        var startingX:Double = start
        
        for activity in activitiesToDraw
        {
            let layerWidth = availableWidth * (activity.duration / totalTimeSpent)
            
            ctx.addRect(CGRect(x: startingX, y: 0, width: layerWidth, height: Double(rect.height)))
            activity.category.color.setFill()
            ctx.drawPath(using: .fill)
            
            startingX += layerWidth
        }
    }
    
    private func animateTransition(_ direction: DailySummaryBarAnimationDirection)
    {
        displayLink?.invalidate()
        displayLink = nil
        
        offset = direction == .right ? Double(frame.width) : Double(-frame.width)
        nextOffset = 0
        
        displayLink = CADisplayLink(target: self, selector: #selector(BarView.animateOffset))
        displayLink?.add(to: .current, forMode: .commonModes)
    }
    
    @objc private func animateOffset()
    {
        let newOffset = offset + (nextOffset - offset) / 10
        if abs(newOffset - nextOffset) < 0.0001
        {
            displayLink?.invalidate()
            displayLink = nil
        }
        
        offset = newOffset
        setNeedsDisplay()
    }
}
