import Foundation
import RxSwift

class SummaryViewModel
{
    let date : Date
    
    init(selectedDateService : SelectedDateService)
    {
        self.date = selectedDateService.currentlySelectedDate
    }
}
