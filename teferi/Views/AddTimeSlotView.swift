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
    @IBOutlet private weak var addButton : AddTimeSlotButton!
    private var wheel : CategoryWheel!
    private let gradientLayer = CAGradientLayer()

    //MARK: Properties
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
    
    var categoryProvider : CategoryProvider? {
        didSet {
            guard let categoryProvider = categoryProvider else { return }
            
            self.wheel = CategoryWheel(frame: self.bounds,
                                       cellSize: CGSize(width: 50.0, height: 50.0),
                                       centerPoint: self.addButton.center,
                                       radius: 144,
                                       startAngle: CGFloat.pi / 4,
                                       endAngle: CGFloat.pi * 5 / 4,
                                       categoryProvider: categoryProvider,
                                       angleBetweenCells: 0.45,
                                       attributeSelector: self.toAttributes,
                                       dismissAction: wheelDismissAction)
        }
    }
    
    //MARK: Lifecycle methods
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.clear
        
        let cornerRadius = CGFloat(25)
        
        self.addButton.layer.cornerRadius = cornerRadius
        
        //Adds some blur to the background of the buttons
        gradientLayer.frame = self.blur.bounds
        gradientLayer.colors = [ UIColor(white: 1.0, alpha: 0.0).cgColor, UIColor(white: 1.0, alpha: 0.8).cgColor]
        gradientLayer.locations = [0.0, 0.6]
        self.blur.layer.addSublayer(gradientLayer)
        self.blur.alpha = 0
        
        //Bindings
        self.categoryObservable
            .subscribe(onNext: onNewCategory)
            .addDisposableTo(disposeBag!)
        
        self.addButton.rx.tap
            .subscribe(onNext: onAddButtonTapped)
            .addDisposableTo(disposeBag!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        wheel.frame = bounds
        gradientLayer.frame = blur.bounds
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
    func wheelDismissAction(wheel: CategoryWheel)
    {
        close()
    }
    
    func close()
    {
        guard self.isAdding == true else { return }
        
        self.isAdding = false
        self.animateAddButton(isAdding: false)
        
        wheel.hide()
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
        self.addButton.changeState(isAdding: isAdding)

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
