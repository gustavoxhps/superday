import Foundation

class MainPresenter
{
    private weak var viewController : MainViewController!    
    private let viewModelLocator : ViewModelLocator
        
    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator) -> MainViewController
    {
        let presenter = MainPresenter(viewModelLocator: viewModelLocator)
        
        let viewController = StoryboardScene.Main.instantiateMain()
        viewController.inject(presenter: presenter, viewModel: viewModelLocator.getMainViewModel())
        
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
    
    func setupPagerViewController(vc:PagerViewController) -> PagerViewController
    {
        return PagerPresenter.create(with: viewModelLocator, fromViewController: vc)
    }
}
