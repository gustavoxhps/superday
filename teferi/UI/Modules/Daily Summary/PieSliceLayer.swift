import UIKit

class PieSliceLayer: CALayer
{
    @NSManaged var startAngle: CGFloat
    @NSManaged var endAngle: CGFloat
    
    private var fillColor: Color = .gray
    var category: Category!
    {
        didSet
        {
            fillColor = category.color
        }
    }
    
    override init()
    {
        super.init()
        
        contentsScale = UIScreen.main.scale
        setNeedsDisplay()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func action(forKey event: String) -> CAAction?
    {
        if event == "startAngle" || event == "endAngle"
        {
            return makeAnimation(forKey: event)
        }
        
        return super.action(forKey: event)
    }

    override init(layer: Any)
    {
        if let layer = layer as? PieSliceLayer
        {
            let other = layer
            fillColor = other.fillColor
        }
        
        super.init(layer: layer)
        
        contentsScale = UIScreen.main.scale
    }
    
    override class func needsDisplay(forKey key: String) -> Bool
    {
        if key == "startAngle" || key == "endAngle"
        {
            return true
        }
        
        return super.needsDisplay(forKey: key)
    }
    
    override func draw(in ctx: CGContext)
    {
        // Create the path
        let center = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
        let radius = min(center.x, center.y)
        
        ctx.beginPath()
        ctx.move(to: center)
        
        let p1 = CGPoint(x: center.x + radius * CGFloat(cos(Float(self.startAngle))), y: center.y + radius * CGFloat(sin(Float(self.startAngle))))
        ctx.addLine(to: p1)
        ctx.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        ctx.closePath()
        
        // Color it
        ctx.setFillColor(fillColor.cgColor)
        
        ctx.drawPath(using: .fill)
    }
    
    private func makeAnimation(forKey key: String) -> CABasicAnimation
    {
        let animation = CABasicAnimation.init(keyPath: key)
        animation.fromValue = presentation()?.value(forKey: key)
        animation.timingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseOut)
        animation.duration = 0.5
        
        return animation
    }
}
