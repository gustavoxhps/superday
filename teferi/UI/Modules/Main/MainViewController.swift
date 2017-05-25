import UIKit
import RxSwift
import MessageUI
import CoreMotion
import CoreGraphics
import QuartzCore
import CoreLocation
import SnapKit

class MainViewController : UIViewController, MFMailComposeViewControllerDelegate
{
    private var viewModel : MainViewModel!
    private var presenter : MainPresenter!
    var viewModelLocator : ViewModelLocator!

    // MARK: Fields
    private let animationDuration = 0.08
    
    private let disposeBag = DisposeBag()
    
    private var pagerViewController : PagerViewController { return self.childViewControllers.firstOfType() }
    
    //Dependencies
    private var editView : EditTimeSlotView!
    private var addButton : AddTimeSlotView!
    
    func inject(presenter:MainPresenter, viewModel: MainViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
    }
    
    // MARK: UIViewController lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //Injecting child ViewController's dependencies
        self.pagerViewController.inject(viewModelLocator: self.viewModelLocator)
        
        //Edit View
        self.editView = EditTimeSlotView(categoryProvider: viewModel.categoryProvider)
        self.view.addSubview(self.editView)
        self.editView.constrainEdges(to: self.view)
        
        //Add button
        self.addButton = (Bundle.main.loadNibNamed("AddTimeSlotView", owner: self, options: nil)?.first) as? AddTimeSlotView
        self.addButton.categoryProvider = viewModel.categoryProvider
        self.view.insertSubview(self.addButton, belowSubview: self.editView)
        self.addButton.constrainEdges(to: self.view)
        
        //Add fade overlay at bottom of timeline
        let bottomFadeOverlay = self.fadeOverlay(startColor: UIColor.white,
                                                 endColor: UIColor.white.withAlphaComponent(0.0))
        
        let fadeView = AutoResizingLayerView(layer: bottomFadeOverlay)
        fadeView.isUserInteractionEnabled = false
        self.view.insertSubview(fadeView, belowSubview: self.addButton)
        fadeView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self.view)
            make.height.equalTo(100)
        }
        
        self.createBindings()
    }
    
    private func createBindings()
    {
        editView.dismissAction = { self.viewModel.notifyEditingEnded() }
        
        //Edit state
        self.viewModel
            .isEditingObservable
            .subscribe(onNext: self.onEditChanged)
            .addDisposableTo(self.disposeBag)
        
        self.viewModel
            .beganEditingObservable
            .subscribe(onNext: self.editView.onEditBegan)
            .addDisposableTo(self.disposeBag)
        
        //Category creation
        self.addButton
            .categoryObservable
            .subscribe(onNext: self.viewModel.addNewSlot)
            .addDisposableTo(self.disposeBag)
        
        self.editView
            .editEndedObservable
            .subscribe(onNext: self.viewModel.updateTimeSlot)
            .addDisposableTo(self.disposeBag)
        
        self.viewModel
            .dateObservable
            .subscribe(onNext: self.onDateChanged)
            .addDisposableTo(self.disposeBag)
        
        self.viewModel.showPermissionControllerObservable
            .subscribe(onNext: self.presenter.showPermissionController)
            .addDisposableTo(self.disposeBag)
    }
    
    // MARK: Methods
    private func onDateChanged(date: Date)
    {
        let today = self.viewModel.currentDate
        let isToday = today.ignoreTimeComponents() == date.ignoreTimeComponents()
        let alpha = CGFloat(isToday ? 1 : 0)
        
        UIView.animate(withDuration: 0.3)
        {
            self.addButton.alpha = alpha
        }
        
        self.addButton.close()
        self.addButton.isUserInteractionEnabled = isToday
    }
    
    private func onEditChanged(_ isEditing: Bool)
    {
        //Close add menu
        self.addButton.close()
        
        //Grey out views
        self.editView.isEditing = isEditing
    }
    
    //Configure overlay
    private func fadeOverlay(startColor: UIColor, endColor: UIColor) -> CAGradientLayer
    {
        let fadeOverlay = CAGradientLayer()
        fadeOverlay.colors = [startColor.cgColor, endColor.cgColor]
        fadeOverlay.locations = [0.1]
        fadeOverlay.startPoint = CGPoint(x: 0.0, y: 1.0)
        fadeOverlay.endPoint = CGPoint(x: 0.0, y: 0.0)
        return fadeOverlay
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        viewModel.active = true
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        viewModel.active = false
    }
}
