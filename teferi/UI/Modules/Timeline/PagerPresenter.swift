import UIKit

class PagerPresenter : NSObject
{
    private weak var viewController : PagerViewController!
    private let viewModelLocator : ViewModelLocator
    fileprivate let swipeInteractionController = SwipeInteractionController()
    
    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator, fromViewController viewController:PagerViewController) -> PagerViewController
    {
        let presenter = PagerPresenter(viewModelLocator: viewModelLocator)
        let viewModel = viewModelLocator.getPagerViewModel()
        
        viewController.inject(presenter: presenter, viewModel: viewModel)
        presenter.viewController = viewController
        
        return viewController
    }
    
    func showDailySummary()
    {
        let vc = SummaryPresenter.create(with: viewModelLocator)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
        viewController.present(vc, animated: true, completion: nil)
        
        swipeInteractionController.wireToViewController(viewController: vc)
    }
    
    func createTimeline(forDate date:Date) -> TimelineViewController
    {
         return TimelinePresenter.create(with: viewModelLocator, andDate: date)
    }
}


extension PagerPresenter : UIViewControllerTransitioningDelegate
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
