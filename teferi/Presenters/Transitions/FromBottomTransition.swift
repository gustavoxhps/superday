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
        return presenting ? 0.225 : 0.195
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
            toController.view.alpha = 0.5
            
            UIView.animate(
                {
                    toController.view.frame = finalFrame
                    toController.view.alpha = 1.0
                },
                duration: animationDuration,
                delay: 0,
                options: [],
                withControlPoints: 0.175, 0.885, 0.32, 1.14,
                completion: {
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            )
        }
        else
        {
            let initialFrame = transitionContext.initialFrame(for: fromController)
            let finalFrame = initialFrame.offsetBy(dx: 0, dy: transitionContext.containerView.frame.height)
            
            if transitionContext.isInteractive
            {
                UIView.animate(
                    withDuration: animationDuration,
                    animations: { 
                        fromController.view.frame = finalFrame
                    },
                    completion: { p in
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                    }
                )
            }
            else
            {
                UIView.animate(
                    {
                        fromController.view.frame = finalFrame
                        fromController.view.alpha = 0.5
                    },
                    duration: animationDuration,
                    delay: 0,
                    options: [],
                    withControlPoints: 0.4, 0.0, 0.6, 1,
                    completion: {
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                    }
                )
            }
        }
    }
}
