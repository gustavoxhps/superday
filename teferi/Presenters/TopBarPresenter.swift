import Foundation
import UIKit

class TopBarPresenter : NSObject
{
    weak var view : TopBarViewController!
    
    fileprivate let swipeInteractionController = SwipeInteractionController()
    
    func showDailySummary(fromRect:CGRect? = nil)
    {
        let vc = DailySummaryPresenter.create()
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
        view.present(vc, animated: true, completion: nil)
        
        swipeInteractionController.wireToViewController(viewController: vc)
    }
}

extension TopBarPresenter:UIViewControllerTransitioningDelegate
{
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return ModalPresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FromBottomTransition(presenting:true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FromBottomTransition(presenting:false)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return swipeInteractionController.interactionInProgress ? swipeInteractionController : nil
    }
}
