import UIKit

class FadeTransition: NSObject, UIViewControllerAnimatedTransitioning
{
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 0.45
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        let toController = transitionContext.viewController(forKey: .to)!
        let fromController = transitionContext.viewController(forKey: .from)!
        let animationDuration = transitionDuration(using: transitionContext)
        
        transitionContext.containerView.insertSubview(toController.view, belowSubview: fromController.view)
        
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options : UIViewAnimationOptions.allowAnimatedContent,
            animations: {
                fromController.view.alpha = 0.0
        },
            completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
