import UIKit

protocol CategoryButtonDelegate:class
{
    func categorySelected(category:Category)
}

class CategoryButton : UIView
{
    private let animationDuration = TimeInterval(0.225)
    
    var category : Category?
    {
        didSet
        {
            guard let category = category else { return }
            
            label.text = category.description
            label.sizeToFit()
            label.center = CGPoint.zero
            label.textColor = category.color
            button.backgroundColor = category.color
            button.setImage(category.icon.image, for: .normal)
        }
    }
    
    var angle : CGFloat = -CGFloat.pi / 2 //The default value is so the label appears at the bottom in EditView
    {
        didSet
        {
            positionLabel()
        }
    }

    weak var delegate:CategoryButtonDelegate?
    
    private let button : UIButton
    private let labelHolder : UIView
    private let label : UILabel
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    required override init(frame: CGRect)
    {
        button = UIButton(frame: frame)
        labelHolder = UIView()
        label = UILabel()
        
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        clipsToBounds = false
        
        button.layer.cornerRadius = min(frame.width, frame.height) / 2
        button.adjustsImageWhenHighlighted = false
        addSubview(button)
        
        label.font = UIFont.boldSystemFont(ofSize: 9)
        label.textAlignment = .center
        
        labelHolder.center = button.center
        
        addSubview(labelHolder)
        labelHolder.addSubview(label)
        
        positionLabel()
        
        button.addTarget(self, action: #selector(CategoryButton.buttonTap), for: .touchUpInside)

    }
    
    
    func show()
    {
        let scaleTransform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        
        self.transform = scaleTransform
        self.isHidden = false
        
        let changesToAnimate = {
            self.layer.removeAllAnimations()
            self.transform = .identity
        }
        
        self.label.alpha = 0
        self.label.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        let showLabelAnimation = {
            self.label.alpha = 1
            self.label.transform = CGAffineTransform.identity
        }
        
        UIView.animate(changesToAnimate, duration: animationDuration, withControlPoints: 0.23, 1, 0.32, 1)
        {
            UIView.animate(
                withDuration: 0.3,
                delay: 0.08,
                usingSpringWithDamping: 0.5,
                initialSpringVelocity: 0.2,
                options: UIViewAnimationOptions.curveEaseOut,
                animations: showLabelAnimation)
        }
    }
    
    func hide()
    {
        let scaleTransform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        
        self.transform = .identity
        self.isHidden = false
        
        let changesToAnimate = {
            self.layer.removeAllAnimations()
            self.transform = scaleTransform
        }
        
        UIView.animate(changesToAnimate, duration: animationDuration, withControlPoints: 0.175, 0.885, 0.32, 1)
    }
    
    private func positionLabel()
    {
        let radius = frame.width / 2 + 12
        let x = button.center.x + radius * cos(angle - CGFloat.pi)
        let y = button.center.y + radius * sin(angle - CGFloat.pi)
        
        labelHolder.center = CGPoint(x: x, y: y)
        
        let labelOffset = -cos(angle)
        label.center = CGPoint(x: labelOffset * (label.frame.width / 2 - label.frame.height / 2), y: 0)
    }
    
    @objc private func buttonTap()
    {
        guard let category = category, let delegate = delegate else { return }
        
        delegate.categorySelected(category: category)
    }
}
