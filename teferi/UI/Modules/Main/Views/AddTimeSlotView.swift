import UIKit
import RxSwift
import QuartzCore
import CoreGraphics

class AddTimeSlotView : UIView
{
    //MARK: Public Properties
    var isAdding : Bool
    {
        get { return self.isAddingVariable.value }
        set(value) { self.isAddingVariable.value = value }
    }
    
    private(set) lazy var categoryObservable : Observable<Category> =
    {
        guard let wheel = self.wheel else { return Observable.empty() }
        
        return wheel.rx.controlEvent(.valueChanged)
            .map { _ in wheel.selectedItem }
            .filterNil()
    }()
    
    var categoryProvider : CategoryProvider?
    {
        didSet
        {
            guard let categoryProvider = categoryProvider else { return }
            
            self.wheel.categoryProvider = categoryProvider
        }
    }
    
    //MARK: Private Properties
    private let isAddingVariable = Variable(false)
    private var disposeBag : DisposeBag? = DisposeBag()
    
    @IBOutlet private weak var blur : UIView!
    @IBOutlet private weak var addButton : AddTimeSlotButton!
    private var wheel : CategoryWheel!
    private let gradientLayer = CAGradientLayer()
    
    //MARK: Lifecycle methods
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        backgroundColor = UIColor.clear
        
        let cornerRadius = CGFloat(25)
        
        addButton.layer.cornerRadius = cornerRadius
        
        wheel = CategoryWheel(frame: bounds,
                              attributeSelector: toAttributes,
                              dismissAction: wheelDismissAction)
        
        //Adds some blur to the background of the buttons
        gradientLayer.frame = blur.bounds
        gradientLayer.colors = [ UIColor(white: 1.0, alpha: 0.0).cgColor, UIColor(white: 1.0, alpha: 0.8).cgColor]
        gradientLayer.locations = [0.0, 0.6]
        blur.layer.addSublayer(gradientLayer)
        blur.alpha = 0
        
        //Bindings
        categoryObservable
            .subscribe(onNext: onNewCategory)
            .addDisposableTo(disposeBag!)
        
        addButton.rx.tap
            .subscribe(onNext: onAddButtonTapped)
            .addDisposableTo(disposeBag!)
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        wheel.frame = bounds
        gradientLayer.frame = blur.bounds
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        for subview in subviews
        {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event)
            {
                return true
            }
        }
        
        return false
    }
    
    //MARK: Methods
    func wheelDismissAction(wheel: CategoryWheel)
    {
        close()
    }
    
    func close()
    {
        guard isAdding == true else { return }
        
        isAdding = false
        animateAddButton(isAdding: false)
        
        wheel.hide()
    }
    
    private func onNewCategory(category: Category)
    {
        isAdding = false
        animateAddButton(isAdding: false)
        
        wheel.hide()
    }
    
    private func onAddButtonTapped()
    {
        isAdding = !isAdding
        animateAddButton(isAdding: isAdding)
        
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
        addButton.changeState(isAdding: isAdding)

        let alpha = CGFloat(isAdding ? 1.0 : 0.0)
   
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
