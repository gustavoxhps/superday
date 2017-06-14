import UIKit

class TimelinePresenter
{
    private weak var viewController : TimelineViewController!
    private let viewModelLocator : ViewModelLocator
    
    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator, andDate date: Date) -> TimelineViewController
    {
        let presenter = TimelinePresenter(viewModelLocator: viewModelLocator)
        let viewModel = viewModelLocator.getTimelineViewModel(forDate: date)
        
        let viewController = TimelineViewController(presenter: presenter, viewModel: viewModel)
        presenter.viewController = viewController
        
        return viewController
    }
}
