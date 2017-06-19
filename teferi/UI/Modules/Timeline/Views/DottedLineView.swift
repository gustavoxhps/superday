import UIKit

class DottedLineView: UIView
{
    var color:UIColor = UIColor.black
        {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
    var spacing:CGFloat = 4
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
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let side = rect.width
        var n:CGFloat = 0
        while n * side + (n-1) * spacing < rect.height
        {
            ctx.addEllipse(in: CGRect(x: 0, y: (side+spacing)*n, width: side, height: side))
            n += 1
        }
        
        color.setFill()
        ctx.drawPath(using: .fill)
    }
    
}
