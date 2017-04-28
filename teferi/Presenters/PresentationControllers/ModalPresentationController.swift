import UIKit

class ModalPresentationController: UIPresentationController
{
    private var dimmingView : UIView!
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?)
    {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        setupDimmingView()
    }
    
    private func setupDimmingView()
    {
        dimmingView = UIView()
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        dimmingView.alpha = 0.0
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(ModalPresentationController.dismiss))
        dimmingView.addGestureRecognizer(recognizer)
    }
    
    @objc private func dismiss()
    {
        presentedViewController.dismiss(animated: true)
    }
    
    override func presentationTransitionWillBegin()
    {
        containerView?.insertSubview(dimmingView, at: 0)
        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        guard let coordinator = presentedViewController.transitionCoordinator
        else {
            dimmingView.alpha = 1.0
            return
        }
        
        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1.0
        })
    }
    
    override func dismissalTransitionWillBegin()
    {
        guard let coordinator = presentedViewController.transitionCoordinator
        else {
            dimmingView.alpha = 0.0
            return
        }
        
        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.0
        })
    }
    
    override func containerViewWillLayoutSubviews()
    {
        presentedView?.frame = frameOfPresentedViewInContainerView
        
        presentedViewController.view.layer.cornerRadius = 10.0
        presentedViewController.view.layer.shadowColor = UIColor.black.cgColor
        presentedViewController.view.layer.shadowOpacity = 0.2
        presentedViewController.view.layer.shadowOffset = CGSize.zero
        presentedViewController.view.layer.shadowRadius = 2
        presentedViewController.view.layer.masksToBounds = false
        presentedViewController.view.layer.shadowPath = UIBezierPath(roundedRect: presentedViewController.view.bounds, cornerRadius: 10.0).cgPath
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize
    {
        return CGSize(width: parentSize.width - 16 * 2, height: parentSize.height - 78 * 2)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect
    {
        let containerSize = containerView!.bounds.size
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController,
                          withParentContainerSize: containerSize)

        frame.origin = CGPoint(x: containerSize.width / 2 - frame.size.width / 2, y: containerSize.height / 2 - frame.size.height / 2)
        return frame
    }
}
