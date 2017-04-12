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
    // MARK: Fields
    private let animationDuration = 0.08
    
    private var isFirstUse = false
    private let disposeBag = DisposeBag()
    private var viewModel : MainViewModel!
    private var viewModelLocator : ViewModelLocator!
    
    private var pagerViewController : PagerViewController { return self.childViewControllers.firstOfType() }
    private var topBarViewController : TopBarViewController { return self.childViewControllers.firstOfType() }
    private var calendarViewController : CalendarViewController { return self.childViewControllers.firstOfType() }
    private var locationPermissionViewController : PermissionViewController!
    private var healthKitPermissionViewController : PermissionViewController!
    
    //Dependencies
    private var editView : EditTimeSlotView!
    private var addButton : AddTimeSlotView!
    private var launchAnim : LaunchAnimationView!
    
    func inject(viewModelLocator: ViewModelLocator, isFirstUse: Bool) -> MainViewController
    {
        self.isFirstUse = isFirstUse
        self.viewModelLocator = viewModelLocator
        self.viewModel = viewModelLocator.getMainViewModel()
        return self
    }
    
    // MARK: UIViewController lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //Injecting child ViewController's dependencies
        self.pagerViewController.inject(viewModelLocator: self.viewModelLocator)
        self.calendarViewController.inject(viewModel: self.viewModelLocator.getCalendarViewModel())
        
        locationPermissionViewController = StoryboardScene.Main.permissionScene.viewController() as! PermissionViewController
        addChildViewController(locationPermissionViewController)
        view.addSubview(locationPermissionViewController.view)
        locationPermissionViewController.didMove(toParentViewController: self)
        locationPermissionViewController.inject(viewModel: self.viewModelLocator.getLocationPermissionViewModel())
        
        if self.viewModel.shouldAddHealthKitPermisionToViewHierarchy()
        {
            healthKitPermissionViewController = StoryboardScene.Main.permissionScene.viewController() as! PermissionViewController
            addChildViewController(healthKitPermissionViewController)
            view.addSubview(healthKitPermissionViewController.view)
            healthKitPermissionViewController.didMove(toParentViewController: self)
            healthKitPermissionViewController.inject(viewModel: self.viewModelLocator.getHealthKitPermissionViewModel())
        }
        
        self.topBarViewController.inject(viewModel: self.viewModelLocator.getTopBarViewModel(forViewController: self),
                                         pagerViewController: self.pagerViewController,
                                         calendarViewController: self.calendarViewController)
        
        //Edit View
        self.editView = EditTimeSlotView(categoryProvider: DefaultCategoryProvider())
        self.view.insertSubview(self.editView, belowSubview: self.calendarViewController.view.superview!)
        self.editView.constrainEdges(to: self.view)
        
        //Add button
        self.addButton = (Bundle.main.loadNibNamed("AddTimeSlotView", owner: self, options: nil)?.first) as? AddTimeSlotView
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
        
        if !self.isFirstUse
        {
            self.launchAnim = LaunchAnimationView(frame: view.frame)
            self.view.addSubview(launchAnim)
        }
        
        self.createBindings()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.startLaunchAnimation()
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
        
    }
    
    // MARK: Methods
    private func startLaunchAnimation()
    {
        guard self.launchAnim != nil else { return }
        
        //Small delay to give launch screen time to fade away
        Timer.schedule(withDelay: 0.1) { _ in
            self.launchAnim?.animate(onCompleted:
            {
                self.launchAnim!.removeFromSuperview()
                self.launchAnim = nil
            })
        }
    }
    
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
}
