import UIKit

class FromBottomTransition: NSObject, UIViewControllerAnimatedTransitioning
{
    let presenting : Bool
    
    init(presenting:Bool)
    {
        self.presenting = presenting
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        let toController = transitionContext.viewController(forKey: .to)!
        let fromController = transitionContext.viewController(forKey: .from)!
        let animationDuration = transitionDuration(using: transitionContext)

        if presenting
        {
            
            transitionContext.containerView.addSubview(toController.view)

            let finalFrame = transitionContext.finalFrame(for: toController)
            toController.view.frame = finalFrame.offsetBy(dx: 0, dy: transitionContext.containerView.frame.height)

            UIView.animate(withDuration: animationDuration,
                           delay: 0,
                           usingSpringWithDamping: 0.75,
                           initialSpringVelocity: 0.2,
                           options: UIViewAnimationOptions.curveEaseOut,
                           animations: {
                                toController.view.frame = finalFrame
                           },
                           completion: { _ in
                                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                           }
            )
            
        }
        else
        {
            let initialFrame = transitionContext.initialFrame(for: fromController)
            let finalFrame = initialFrame.offsetBy(dx: 0, dy: transitionContext.containerView.frame.height)

            UIView.animate(withDuration: animationDuration,
                           delay:0,
                           options: UIViewAnimationOptions.curveLinear,
                           animations: {
                                fromController.view.frame = finalFrame
                           },
                           completion: { _ in
                                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                           }
            )
        }
    }
}
