import UIKit
import RxSwift
import Foundation

class PermissionViewController : UIViewController
{
    //MARK: Fields
    private let disposeBag = DisposeBag()
    private var viewModel : PermissionViewModel!
    
    @IBOutlet private weak var titleLabel : UILabel!
    @IBOutlet private weak var descriptionLabel : UILabel!
    @IBOutlet private weak var remindLaterButton : UIButton!
    @IBOutlet private weak var enableLocationButton : UIButton!
    
    // MARK: Methods
    func inject(viewModel: PermissionViewModel)
    {
        self.viewModel = viewModel
        
        self.initializeBindings()
    }
    
    private func initializeBindings()
    {
        self.viewModel
            .showOverlayObservable
            .subscribe(onNext: self.showOverlay)
            .addDisposableTo(self.disposeBag)
        
        self.viewModel
            .hideOverlayObservable
            .subscribe(onNext: self.hideOverlay)
            .addDisposableTo(self.disposeBag)
        
        self.enableLocationButton.rx.tap
            .flatMapLatest(getUserLocationPermission)
            .subscribe(onNext: onPermissionGiven)
            .addDisposableTo(self.disposeBag)
        
        self.remindLaterButton
            .rx.tap
            .subscribe(onNext: self.onRemindLaterTapped)
            .addDisposableTo(self.disposeBag)
    }
    
    private func getUserLocationPermission() -> Observable<Void>
    {
        let url = URL(string: UIApplicationOpenSettingsURLString)!
        UIApplication.shared.openURL(url)
        
        return self.viewModel.permissionGivenObservable
    }
    
    private func onPermissionGiven()
    {
        self.viewModel.permissionGiven()
    }
    
    private func onRemindLaterTapped()
    {
        self.viewModel.permissionDeferred()
        self.hideOverlay()
    }
    
    private func showOverlay()
    {
        self.titleLabel.text = self.viewModel.titleText
        self.descriptionLabel.text = self.viewModel.descriptionText
        self.remindLaterButton.isHidden = self.viewModel.isFirstTimeUser
        
        self.view.isUserInteractionEnabled = true
        self.view.superview!.isUserInteractionEnabled = true
        self.view.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        
        UIView.animate(withDuration: Constants.editAnimationDuration,
                       animations: { self.view.alpha = 1 })
    }
    
    private func hideOverlay()
    {
        UIView.animate(withDuration: Constants.editAnimationDuration,
                       animations: { self.view.alpha = 0 })
        
        self.view.backgroundColor = UIColor.clear
        self.view.isUserInteractionEnabled = false
        self.view.superview!.isUserInteractionEnabled = false
    }
}
