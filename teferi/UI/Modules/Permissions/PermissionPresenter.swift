import UIKit

enum PermissionRequestType
{
    case health
    case location
}

class PermissionPresenter
{
    private weak var viewController : PermissionViewController!
    
    private let viewModelLocator : ViewModelLocator
    
    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator, type:PermissionRequestType) -> PermissionViewController
    {
        let presenter = PermissionPresenter(viewModelLocator: viewModelLocator)
        
        let viewController = StoryboardScene.Main.instantiatePermission()
        let viewModel = permissionViewModel(forType: type, viewModelLocator: viewModelLocator)
        viewController.inject(presenter: presenter, viewModel: viewModel)
        
        presenter.viewController = viewController
        
        return viewController
    }
    
    private static func permissionViewModel(forType type:PermissionRequestType, viewModelLocator:ViewModelLocator) -> PermissionViewModel
    {
        switch type {
        case .health:
            return viewModelLocator.getHealthKitPermissionViewModel()
        default:
            return viewModelLocator.getLocationPermissionViewModel()
        }
    }
    
    func dismiss()
    {
        viewController.dismiss(animated: true)
    }
}
