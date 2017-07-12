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
    // MARK: Private Properties
    private var viewModel : MainViewModel!
    private var presenter : MainPresenter!

    private var pagerViewController : PagerViewController!
    
    private let disposeBag = DisposeBag()
    
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
        
        pagerViewController = presenter.setupPagerViewController(vc: self.childViewControllers.firstOfType())
        
        //Edit View
        editView = EditTimeSlotView(categoryProvider: viewModel.categoryProvider)
        view.addSubview(editView)
        editView.constrainEdges(to: view)
        
        //Add button
        addButton = (Bundle.main.loadNibNamed("AddTimeSlotView", owner: self, options: nil)?.first) as? AddTimeSlotView
        addButton.categoryProvider = viewModel.categoryProvider
        view.insertSubview(addButton, belowSubview: editView)
        addButton.constrainEdges(to: view)
        
        //Add fade overlay at bottom of timeline
        let bottomFadeOverlay = fadeOverlay(startColor: UIColor.white,
                                                 endColor: UIColor.white.withAlphaComponent(0.0))
        
        let fadeView = AutoResizingLayerView(layer: bottomFadeOverlay)
        fadeView.isUserInteractionEnabled = false
        view.insertSubview(fadeView, belowSubview: addButton)
        fadeView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(view)
            make.height.equalTo(100)
        }
        
        createBindings()
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
    
    // MARK: Private Methods
    
    private func createBindings()
    {
        editView.dismissAction = { [unowned self] in self.viewModel.notifyEditingEnded() }
        
        //Edit state
        viewModel
            .isEditingObservable
            .subscribe(onNext: onEditChanged)
            .addDisposableTo(disposeBag)
        
        viewModel
            .beganEditingObservable
            .subscribe(onNext: editView.onEditBegan)
            .addDisposableTo(disposeBag)
        
        //Category creation
        addButton
            .categoryObservable
            .subscribe(onNext: viewModel.addNewSlot)
            .addDisposableTo(disposeBag)
        
        editView
            .editEndedObservable
            .subscribe(onNext: viewModel.updateTimelineItem)
            .addDisposableTo(disposeBag)
        
        viewModel
            .dateObservable
            .subscribe(onNext: onDateChanged)
            .addDisposableTo(disposeBag)
        
        viewModel.showPermissionControllerObservable
            .subscribe(onNext: presenter.showPermissionController)
            .addDisposableTo(disposeBag)
    }
    
    private func onDateChanged(date: Date)
    {
        let today = viewModel.currentDate
        let isToday = today.ignoreTimeComponents() == date.ignoreTimeComponents()
        let alpha = CGFloat(isToday ? 1 : 0)
        
        UIView.animate(withDuration: 0.3)
        {
            self.addButton.alpha = alpha
        }
        
        addButton.close()
        addButton.isUserInteractionEnabled = isToday
    }
    
    private func onEditChanged(_ isEditing: Bool)
    {
        //Close add menu
        addButton.close()
        
        //Grey out views
        editView.isEditing = isEditing
    }
    
    private func fadeOverlay(startColor: UIColor, endColor: UIColor) -> CAGradientLayer
    {
        let fadeOverlay = CAGradientLayer()
        fadeOverlay.colors = [startColor.cgColor, endColor.cgColor]
        fadeOverlay.locations = [0.1]
        fadeOverlay.startPoint = CGPoint(x: 0.0, y: 1.0)
        fadeOverlay.endPoint = CGPoint(x: 0.0, y: 0.0)
        return fadeOverlay
    }
}
