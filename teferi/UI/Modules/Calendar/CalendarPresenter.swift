import Foundation

class CalendarPresenter
{
    private weak var viewController : CalendarViewController!
    private let viewModelLocator : ViewModelLocator
    
    private let dismissCallback : () -> ()
    
    private init(viewModelLocator: ViewModelLocator, dismissCallBack: @escaping () -> ())
    {
        self.viewModelLocator = viewModelLocator
        self.dismissCallback = dismissCallBack
    }
    
    static func create(with viewModelLocator: ViewModelLocator, dismissCallback: @escaping () -> ()) -> CalendarViewController
    {
        let presenter = CalendarPresenter(viewModelLocator: viewModelLocator, dismissCallBack: dismissCallback)
        
        let viewController = StoryboardScene.Main.instantiateCalendar()
        viewController.inject(presenter: presenter, viewModel: viewModelLocator.getCalendarViewModel())
        
        presenter.viewController = viewController
        
        return viewController
    }
    
    func dismiss()
    {
        dismissCallback()
    }
}
