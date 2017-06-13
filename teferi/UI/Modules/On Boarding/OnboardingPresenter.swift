import Foundation

class OnboardingPresenter
{
    //MARK: Private Properties
    private weak var viewController : OnboardingViewController!
    private let viewModelLocator : ViewModelLocator
    
    //MARK: Initializer
    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator) -> OnboardingViewController
    {
        let presenter = OnboardingPresenter(viewModelLocator: viewModelLocator)
        
        let viewController = StoryboardScene.Onboarding.instantiateOnboarding()
        viewController.inject(presenter: presenter, viewModel: viewModelLocator.getOnboardingViewModel())
        
        presenter.viewController = viewController
        
        return viewController
    }
    
    //MARK: Public Methods
    func showMain()
    {
        let nav = NavigationPresenter.create(with: viewModelLocator)
        nav.modalTransitionStyle = .crossDissolve
        viewController.present(nav, animated: true)
    }
    
}
