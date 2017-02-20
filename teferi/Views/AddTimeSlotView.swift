import UIKit
import RxSwift
import QuartzCore
import CoreGraphics

class AddTimeSlotView : UIView
{
    //MARK: Fields
    private let isAddingVariable = Variable(false)
    private var selectedCategory = Variable(Category.unknown)
    private var disposeBag : DisposeBag? = DisposeBag()
    
    @IBOutlet private weak var blur : RadialGradientView!
    @IBOutlet private weak var addButton : UIButton!
    private var wheel : Wheel<Category>!

    //MARK: Properties
    var isAdding : Bool
    {
        get { return self.isAddingVariable.value }
        set(value) { self.isAddingVariable.value = value }
    }
    
    lazy var categoryObservable : Observable<Category> =
    {
        return self.selectedCategory.asObservable()
    }()
    
    //MARK: Lifecycle methods
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.clear
        
        let cornerRadius = CGFloat(25)
        
        self.addButton.layer.cornerRadius = cornerRadius
        
        wheel = Wheel(frame: self.bounds,
                      cellSize: CGSize(width: 50.0, height: 50.0),
                      centerPoint: self.addButton.center,
                      radius: 120,
                      startAngle: CGFloat.pi / 4,
                      endAngle: CGFloat.pi * 5 / 4,
                      angleBetweenCells: CGFloat.pi * 2 / 12,
                      items: Category.all,
                      attributeSelector: self.toAttributes)
        
        wheel.addTarget(self, action: #selector(AddTimeSlotView.wheelChangedValue), for: .valueChanged)
        
        //Bindings
        self.categoryObservable
            .subscribe(onNext: onNewCategory)
            .addDisposableTo(disposeBag!)
        
        self.addButton.rx.tap
            .subscribe(onNext: onAddButtonTapped)
            .addDisposableTo(disposeBag!)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        for subview in self.subviews
        {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event)
            {
                return true
            }
        }
        
        return false
    }
    
    //MARK: Methods
    func close()
    {
        guard self.isAdding == true else { return }
        
        self.isAdding = false
        self.animateAddButton(isAdding: false)
    }
    
    func wheelChangedValue()
    {
        selectedCategory.value = wheel.selectedItem!
    }
    
    private func onNewCategory(category: Category)
    {
        self.isAdding = false
        self.animateAddButton(isAdding: false)
        
        wheel.hide()
    }
    
    private func onAddButtonTapped()
    {
        self.isAdding = !self.isAdding
        self.animateAddButton(isAdding: self.isAdding)
        
        if isAdding
        {
            wheel.show(below: addButton)
        }
        else
        {
            wheel.hide()
        }
    }
    
    private func animateAddButton(isAdding: Bool)
    {
        let alpha = CGFloat(isAdding ? 1.0 : 0.0)
        let degrees = isAdding ? 45.0 : 0.0
        let options = isAdding ? UIViewAnimationOptions.curveEaseOut : UIViewAnimationOptions.curveEaseIn

        let delay : TimeInterval = 0
        
        blur.radialGradientCenterPoint = addButton.center
        blur.radius = min(addButton.center.x, addButton.center.y)
        
        UIView.animate(withDuration: 0.2, delay: delay,
            options: options,
            animations:
            {
                //Add button
                self.addButton.transform = CGAffineTransform(rotationAngle: CGFloat(degrees * (Double.pi / 180.0)));
            },
            completion: nil)

        UIView.animate(withDuration: 0.25)
        {
            self.blur.alpha = alpha
        }
    }
    
    private func toAttributes(category: Category) -> (UIImage, UIColor)
    {
        return (category.icon.image, category.color)
    }
}
