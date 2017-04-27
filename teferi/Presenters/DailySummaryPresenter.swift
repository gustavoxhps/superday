import UIKit

class DailySummaryPresenter
{
    weak var view : DailySummaryViewController!
    
    static func create() -> DailySummaryViewController
    {
        let presenter = DailySummaryPresenter()
        
        let view = DailySummaryViewController()

        view.viewModel = DailySummaryViewModel()
        view.presenter = presenter
        
        presenter.view = view
        
        return view
    }
}
