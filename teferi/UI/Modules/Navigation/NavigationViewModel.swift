import RxSwift
import Foundation

class NavigationViewModel
{
    // MARK: Fields
    private let currentDayBarTitle = L10n.currentDayBarTitle
    private let yesterdayBarTitle = L10n.yesterdayBarTitle
    
    private let timeService: TimeService
    private let feedbackService: FeedbackService
    private let selectedDateService : SelectedDateService
    private let appLifecycleService: AppLifecycleService
    
    private let dayOfMonthFormatter : DateFormatter
    
    // MARK: Initializers
    init(timeService : TimeService,
         feedbackService: FeedbackService,
         selectedDateService: SelectedDateService,
         appLifecycleService: AppLifecycleService)
    {
        self.timeService = timeService
        self.feedbackService = feedbackService
        self.selectedDateService = selectedDateService
        self.appLifecycleService = appLifecycleService
        
        dayOfMonthFormatter = DateFormatter()
        dayOfMonthFormatter.timeZone = TimeZone.autoupdatingCurrent
        dayOfMonthFormatter.dateFormat = "EEE, dd MMM"
    }
    
    // MARK: Properties
    var calendarDay : Observable<String>
    {
        return self.appLifecycleService.movedToForegroundObservable
            .startWith(())
            .map { [unowned self] in
                let currentDay = Calendar.current.component(.day, from: self.timeService.now)
                return String(format: "%02d", currentDay)
        }
    }
    
    var title : Observable<String>
    {
        return Observable.combineLatest(
            self.selectedDateService.currentlySelectedDateObservable,
            self.appLifecycleService.movedToForegroundObservable.startWith(())) { date, _ in
                return date
            }
            .map(titleForDate)
    }
    
    private func titleForDate(date:Date) -> String
    {
        let currentDate = date.ignoreTimeComponents()
        let today = timeService.now.ignoreTimeComponents()
        let yesterday = today.yesterday.ignoreTimeComponents()
        
        if currentDate == today
        {
            return currentDayBarTitle
        }
        else if currentDate == yesterday
        {
            return yesterdayBarTitle
        }
        
        return dayOfMonthFormatter.string(from: currentDate)
    }
    
    func composeFeedback() { feedbackService.composeFeedback() }
}
