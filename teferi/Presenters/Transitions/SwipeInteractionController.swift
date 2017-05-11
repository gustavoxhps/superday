import UIKit

class SwipeInteractionController : UIPercentDrivenInteractiveTransition
{
    var interactionInProgress = false
    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!
    
    func wireToViewController(viewController: UIViewController!)
    {
        self.viewController = viewController
        prepareGestureRecognizerInView(view: viewController.view)
    }
    
    private func prepareGestureRecognizerInView(view: UIView)
    {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(SwipeInteractionController.handleGesture(recognizer:)))
        view.addGestureRecognizer(gesture)
    }
    
    func handleGesture(recognizer: UIPanGestureRecognizer)
    {
        let translation = recognizer.translation(in: recognizer.view!.superview!)
        let percent = translation.y / recognizer.view!.superview!.bounds.size.height

        switch recognizer.state {
            
        case .began:
            interactionInProgress = true
            viewController.dismiss(animated: true, completion: nil)
            
        case .changed:
            shouldCompleteTransition = percent > 0.2
            update(percent)
            
        case .cancelled:
            interactionInProgress = false
            cancel()
            
        case .ended:
            interactionInProgress = false
            
            if !shouldCompleteTransition
            {
                cancel()
            }
            else
            {
                finish()
            }
            
        default:
            print("Unsupported")
        }
    }
}


