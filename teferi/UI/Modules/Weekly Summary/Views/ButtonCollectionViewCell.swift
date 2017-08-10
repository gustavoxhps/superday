import UIKit

struct CategoryButtonModel
{
    let category: Category
    let enabled: Bool
}

class ButtonCollectionViewCell: UICollectionViewCell
{
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var circle: CategoryButtonCircleView!
    
    var model: CategoryButtonModel?
    {
        didSet
        {
            configure()
        }
    }
    
    override var isSelected: Bool
    {
        didSet
        {
            guard let model = model else { return }
            label.textColor = isSelected ? model.category.color : Style.Color.gray
            circle.enabled = isSelected
        }
    }
    
    private func configure()
    {
        guard let model = model else { return }
        
        label.text = model.category.description
        circle.color = model.category.color
        
        isSelected = model.enabled
    }
}

class CategoryButtonCircleView: UIView
{
    var enabled: Bool = true
    {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var color: UIColor = UIColor.black
    {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect)
    {        
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        ctx.addEllipse(in: CGRect(x: rect.width/2 - 4, y: rect.height/2-4, width: 8, height: 8))
        
        if enabled {
            ctx.setLineWidth(2)
            color.setStroke()
            ctx.drawPath(using: .stroke)
        } else {
            Style.Color.gray.setFill()
            ctx.drawPath(using: .fill)
        }
        
    }
}
