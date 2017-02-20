import UIKit

@IBDesignable
class RadialGradientView: UIView
{
    @IBInspectable var radialGradientCenterPoint: CGPoint = .zero
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    @IBInspectable var radius: CGFloat = 500.0
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    @IBInspectable var gradientFirstColor: UIColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    @IBInspectable var gradientSecondColor: UIColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 0.000)
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect)
    {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Gradient Declarations
        let gradient = CGGradient(colorsSpace: nil, colors: [gradientFirstColor.cgColor, gradientSecondColor.cgColor] as CFArray, locations: [0, 0.5, 1])!
        
        //// Rectangle Drawing
        let rectanglePath = UIBezierPath(rect: rect)
        context.saveGState()
        rectanglePath.addClip()
        context.drawRadialGradient(gradient,
                                   startCenter: radialGradientCenterPoint, startRadius: 0.0,
                                   endCenter: radialGradientCenterPoint, endRadius: radius * contentScaleFactor,
                                   options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        context.restoreGState()
    }
}
