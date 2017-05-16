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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect)
    {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        backgroundColor = UIColor.clear
        
        let line = UIBezierPath(roundedRect: rect, cornerRadius: rect.width/2)
        ctx.addPath(line.cgPath)
        
        if fading
        {
            ctx.clip()
            let colors = [color.cgColor, UIColor.white.cgColor] as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors , locations: nil)
            
            let gradientHeight = min(100, rect.height)
            ctx.drawLinearGradient(gradient!, start: CGPoint(x:0, y:rect.height - gradientHeight), end: CGPoint(x:rect.origin.x, y:rect.height), options: CGGradientDrawingOptions.drawsBeforeStartLocation)
        }
        else {
            color.setFill()
            ctx.drawPath(using: .fill)
        }
    }
}
