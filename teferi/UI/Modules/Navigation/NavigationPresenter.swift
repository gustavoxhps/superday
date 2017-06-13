import UIKit

class NavigationPresenter : NSObject
{
    private weak var viewController : NavigationController!
    private let viewModelLocator : ViewModelLocator
    
    private var calendarViewController : CalendarViewController? = nil
    fileprivate let swipeInteractionController = SwipeInteractionController()

    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator) -> NavigationController
    {
        let presenter = NavigationPresenter(viewModelLocator: viewModelLocator)
        
        let mainViewController = MainPresenter.create(with: viewModelLocator)
        let viewController = NavigationController(rootViewController: mainViewController)
        viewController.inject(presenter: presenter, viewModel: viewModelLocator.getNavigationViewModel(forViewController: viewController))
        
        presenter.viewController = viewController
        
        return viewController
    }
    
    func showPermissionController(type: PermissionRequestType)
    {
        let vc = PermissionPresenter.create(with: viewModelLocator, type: type)
        vc.modalPresentationStyle = .custom
        vc.modalTransitionStyle = .crossDissolve
        viewController.present(vc, animated: true)
    }
    
    func toggleCalendar()
    {
        if let _ = calendarViewController {
            hideCalendar()
        } else {
            showCalendar()
        }
    }    
    
    func showSummary()
    {
        let vc = WeeklySummaryPresenter.create(with: viewModelLocator)
        viewController.present(vc, animated: true, completion: nil)
    }
    
    private func showCalendar()
    {
        calendarViewController = CalendarPresenter.create(with: viewModelLocator, dismissCallback: didHideCalendar)
        viewController.topViewController?.addChildViewController(calendarViewController!)        
        viewController.topViewController?.view.addSubview(calendarViewController!.view)
        calendarViewController!.didMove(toParentViewController: viewController.topViewController)
    }
    
    private func hideCalendar()
    {
        calendarViewController?.hide()
    }
    
    private func didHideCalendar()
    {
        guard let calendar = calendarViewController else { return }
        
        calendar.willMove(toParentViewController: nil)
        calendar.view.removeFromSuperview()
        calendar.removeFromParentViewController()
        
        calendarViewController = nil
    }
}

extension NavigationPresenter: UIViewControllerTransitioningDelegate
{
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController?
    {
        return ModalPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return FromBottomTransition(presenting:true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return FromBottomTransition(presenting:false)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    {
        return swipeInteractionController.interactionInProgress ? swipeInteractionController : nil
    }
}
