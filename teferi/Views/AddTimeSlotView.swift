import UIKit
import RxSwift
import QuartzCore
import CoreGraphics

class AddTimeSlotView : UIView
{
    //MARK: Fields
    private let isAddingVariable = Variable(false)
    private var disposeBag : DisposeBag? = DisposeBag()
    
    @IBOutlet private weak var blur : UIView!
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
        let taps = Category.unknown//self.buttons.map
//        { (category, button) in
//            button.rx.tap.map { _ in return category }
//        }
        return Observable.from([taps])
    }()
    
    //MARK: Lifecycle methods
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.clear
        
        let cornerRadius = CGFloat(25)
        
        self.addButton.layer.cornerRadius = cornerRadius
        
        //Adds some blur to the background of the buttons
        self.blur.frame = bounds;
        let layer = CAGradientLayer()
        layer.frame = self.blur.bounds
        layer.colors = [ Color.white.withAlphaComponent(0).cgColor, Color.white.cgColor]
        layer.locations = [0.0, 1.0]
        self.blur.layer.addSublayer(layer)
        self.blur.alpha = 0
        
        wheel = Wheel(frame: self.bounds,
                      cellSize: CGSize(width: 50.0, height: 50.0),
                      centerPoint: self.addButton.center,
                      radius: 170,
                      startAngle: CGFloat.pi / 4,
                      endAngle: CGFloat.pi * 5 / 4,
                      angleBetweenCells: CGFloat.pi * 2 / 12.5,
                      items: Category.all,
                      attributeSelector: self.toAttributes)
        
        //Bindings
        self.categoryObservable
            .subscribe(onNext: onNewCategory)
            .addDisposableTo(disposeBag!)
        
        self.addButton.rx.tap
            .subscribe(onNext: onAddButtonTapped)
            .addDisposableTo(disposeBag!)
    }
    
//    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
//    {
//        for subview in self.subviews
//        {
//            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event)
//            {
//                return true
//            }
//        }
//        
//        return false
//    }
    
    //MARK: Methods
    func close()
    {
        guard self.isAdding == true else { return }
        
        self.isAdding = false
        self.animateButtons(isAdding: false)
    }
    
    private func onNewCategory(category: Category)
    {
        self.isAdding = false
        self.animateButtons(isAdding: false, category: category)
    }
    
    private func onAddButtonTapped()
    {
        self.isAdding = !self.isAdding
        self.animateButtons(isAdding: self.isAdding)
        
        if isAdding
        {
            wheel.centerPoint = addButton.center
            insertSubview(wheel, belowSubview: addButton)
        }
        else
        {
            wheel.removeFromSuperview()
        }
    }
    
    private func animateButtons(isAdding: Bool, category: Category = .unknown)
    {
        let alpha = CGFloat(isAdding ? 1.0 : 0.0)
        let degrees = isAdding ? 45.0 : 0.0
        let options = isAdding ? UIViewAnimationOptions.curveEaseOut : UIViewAnimationOptions.curveEaseIn

        let delay : TimeInterval = 0
        
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
