import UIKit

class LineView: UIView
{
    var color:UIColor = UIColor.black
        {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    var fading:Bool = false
        {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    var collapsable: Bool = false
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect)
    {        
        backgroundColor = UIColor.clear
        let dotsHeight:CGFloat = 24
        
        if collapsable {
            drawLine(inRect: CGRect(x: 0, y: 0, width: rect.width, height: rect.height / 2 - dotsHeight / 2))
            drawDottedLine(inRect: CGRect(x: 0, y: rect.height / 2 - dotsHeight / 2 + rect.width, width: rect.width, height: dotsHeight - rect.width*2))
            drawLine(inRect: CGRect(x: 0, y: rect.height / 2 + dotsHeight / 2, width: rect.width, height: rect.height / 2 - dotsHeight / 2))
        } else {
            drawSingleLine(inRect: rect)
        }
    }
    
    private func drawLine(inRect rect: CGRect)
    {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let line = UIBezierPath(roundedRect: rect, cornerRadius: rect.width/2)
        ctx.addPath(line.cgPath)
        color.setFill()
        ctx.drawPath(using: .fill)
    }
    
    private func drawDottedLine(inRect rect: CGRect)
    {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let spacing:CGFloat = 2
        let side = rect.width
        var n:CGFloat = 0
        while n * side + (n-1) * spacing < rect.height
        {
            ctx.addEllipse(in: CGRect(x: rect.origin.x, y: rect.origin.y + (side+spacing)*n, width: side, height: side))
            n += 1
        }
        
        color.setFill()
        ctx.drawPath(using: .fill)
    }
    
    func drawSingleLine(inRect rect: CGRect)
    {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let line = UIBezierPath(roundedRect: rect, cornerRadius: rect.width/2)
        ctx.addPath(line.cgPath)
        
        if fading
        {
            ctx.clip()
            let colors = [color.cgColor, UIColor.white.cgColor] as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)
            
            let gradientHeight = min(100, rect.height)
            ctx.drawLinearGradient(gradient!, start: CGPoint(x:0, y:rect.height - gradientHeight), end: CGPoint(x:rect.origin.x, y:rect.height), options: CGGradientDrawingOptions.drawsBeforeStartLocation)
        }
        else {
            color.setFill()
            ctx.drawPath(using: .fill)
        }
    }
}
