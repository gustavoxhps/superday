import UIKit

class WeeklySummaryPresenter
{
    private weak var viewController : WeeklySummaryViewController!
    private let viewModelLocator : ViewModelLocator
    
    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator) -> WeeklySummaryViewController
    {
        let presenter = WeeklySummaryPresenter(viewModelLocator: viewModelLocator)
        
        let viewController = StoryboardScene.WeeklySummary.instantiateWeeklySummary()
        viewController.inject(presenter: presenter, viewModel: viewModelLocator.getWeeklySummaryViewModel())
        
        presenter.viewController = viewController
        
        return viewController
    }
    
    func dismiss()
    {
        viewController.dismiss(animated: true)
    }
}
