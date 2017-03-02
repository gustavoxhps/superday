import RxSwift
import Foundation

class TopBarViewModel
{
    // MARK: Fields
    private let currentDayBarTitle = L10n.currentDayBarTitle
    private let yesterdayBarTitle = L10n.yesterdayBarTitle
    
    private let timeService: TimeService
    private let feedbackService: FeedbackService
    private let dayOfMonthFormatter : DateFormatter
    private let selectedDateService : SelectedDateService
    
    // MARK: Initializers
    init(timeService : TimeService,
         feedbackService: FeedbackService,
         selectedDateService: SelectedDateService)
    {
        self.timeService = timeService
        self.feedbackService = feedbackService
        self.selectedDateService = selectedDateService
        
        self.dateObservable = self.selectedDateService.currentlySelectedDateObservable
        
        self.dayOfMonthFormatter = DateFormatter()
        self.dayOfMonthFormatter.timeZone = TimeZone.autoupdatingCurrent
        self.dayOfMonthFormatter.dateFormat = "EEE, dd MMM"
    }
    
    // MARK: Properties
    
    ///Current date for the calendar button
    let dateObservable : Observable<Date>
    
    var calendarDay : String
    {
        let currentDay = Calendar.current.component(.day, from: self.timeService.now)
        return String(format: "%02d", currentDay)
    }
    
    ///Gets the title for the header. Changes on new locations.
    var title : String
    {
        let today = self.timeService.now.ignoreTimeComponents()
        let yesterday = today.yesterday.ignoreTimeComponents()
        let currentlySelectedDate = self.selectedDateService.currentlySelectedDate.ignoreTimeComponents()
        
        if currentlySelectedDate == today
        {
            return self.currentDayBarTitle
        }
        else if currentlySelectedDate == yesterday
        {
            return self.yesterdayBarTitle
        }
        
        return dayOfMonthFormatter.string(from: currentlySelectedDate)
    }
    
    func composeFeedback() { self.feedbackService.composeFeedback() }
}
