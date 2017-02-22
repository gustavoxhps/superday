import UIKit

class EditTimeSlotView : UIView
{
    //MARK: Fields
    private var editButtons : [UIImageView]? = nil
    private var onEditEnded : ((TimeSlot, Category) -> Void)!
    private var firstImageView : UIImageView? = nil
    
    //MARK: Initializers
    init(editEndedCallback: @escaping (TimeSlot, Category) -> Void)
    {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        self.alpha = 0
        self.onEditEnded = editEndedCallback
        self.backgroundColor = Color.white.withAlphaComponent(0)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Properties
    var isEditing : Bool = false
    {
        didSet
        {
            guard !isEditing else { return }
            guard let viewsToRemove = self.editButtons else { return }
            
            var animationDelay = Double(viewsToRemove.count - 1) * Constants.editAnimationDuration
            
            UIView.animate(withDuration: Constants.editAnimationDuration * 3,
                           delay: animationDelay - Constants.editAnimationDuration * 3,
                           options: .curveLinear,
                           animations:  {
                                self.backgroundColor = Color.white.withAlphaComponent(0)
                                self.firstImageView!.alpha = 0
                            },
                           completion: { (_) in
                                self.alpha = 0
                                self.firstImageView!.removeFromSuperview()
                            } )
            
            viewsToRemove.forEach { v in
                
                UIView.animate(withDuration: Constants.editAnimationDuration,
                               delay: animationDelay,
                               options: [ .curveEaseInOut ],
                               animations: { v.alpha = 0 },
                               completion: { _ in v.removeFromSuperview()} )
                
                animationDelay -= Constants.editAnimationDuration
            }
            
            self.editButtons = nil
        }
    }
    
    //MARK: Methods
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        return self.alpha > 0
    }
    
    func onEditBegan(point: CGPoint, timeSlot: TimeSlot)
    {
        guard point.x != 0 && point.y != 0 else { return }
        
        self.alpha = 1
        
        self.editButtons = Category.all
            .filter { c in c != .unknown && c != timeSlot.category }
            .map { category in return self.mapCategoryIntoView(category, timeSlot) }
        
        let firstImageView = UIImageView(image: UIImage(asset: Category.unknown.icon))
        firstImageView.backgroundColor = timeSlot.category.color
        firstImageView.layer.cornerRadius = 16
        firstImageView.contentMode = .center
        firstImageView.alpha = 0
        
        self.addSubview(firstImageView)
        firstImageView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.top.equalTo(point.y - 24)
            make.left.equalTo(point.x - 32)
        }
        
        UIView.animate(withDuration: Constants.editAnimationDuration * 3)
        {
            self.backgroundColor = Color.white.withAlphaComponent(0.6)
            firstImageView.alpha = 1
        }
        
        var animationDelay = 0.0
        var previousImageView = firstImageView
        for imageView in self.editButtons!
        {
            self.addSubview(imageView)
            
            let previousSnp = previousImageView.snp
            
            imageView.snp.makeConstraints { make in
                
                make.width.width.equalTo(44)
                make.width.height.equalTo(44)
                make.centerY.equalTo(previousSnp.centerY)
                make.left.equalTo(previousSnp.right).offset(5)
            }
            
            UIView.animate(withDuration: Constants.editAnimationDuration,
                           delay: animationDelay,
                           options: [ .curveEaseInOut ],
                           animations: { imageView.alpha = 1 })
            
            animationDelay += Constants.editAnimationDuration
            previousImageView = imageView
        }
        
        self.firstImageView = firstImageView
    }
    
    private func mapCategoryIntoView(_ category: Category, _ timeSlot: TimeSlot) -> UIImageView
    {
        let image = UIImage(asset: category.icon)
        let imageView = UIImageView(image: image)
        let gestureRecognizer = ClosureGestureRecognizer(withClosure:
        {
            self.onEditEnded(timeSlot, category)
        })
        
        imageView.alpha = 0
        imageView.contentMode = .center
        imageView.layer.cornerRadius = 22
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = category.color
        imageView.addGestureRecognizer(gestureRecognizer)
        
        return imageView
    }
    
    // for hacky onboarding animations
    func getIcon(forCategory category: Category) -> UIImageView?
    {
        let color = category.color
        return self.editButtons?.first(where: { (b) in b.backgroundColor == color })
    }
}
