import RxSwift
import Foundation

class PagerViewModel
{
    //MARK: Public Properties
    private(set) lazy var dateObservable : Observable<DateChange> =
    {
        return self.selectedDateService
            .currentlySelectedDateObservable
            .map(self.toDateChange)
            .filterNil()
    }()
    
    private(set) lazy var newDayObservable : Observable<Void> =
    {
        return self.appLifecycleService.movedToForegroundObservable
            .filter {
                self.lastRefresh.differenceInDays(toDate:self.timeService.now) > 0
            }
            .do(onNext: {
                self.lastRefresh = self.timeService.now
            })
    }()
    
    let isEditingObservable : Observable<Bool>
    
    var currentDate : Date { return self.timeService.now }
    
    private(set) lazy var showEditOnLastObservable : Observable<Void> =
    {
        return self.appLifecycleService.startedOnNotificationObservable
    }()
    
    var currentlySelectedDate : Date
    {
        get { return self.selectedDate.ignoreTimeComponents() }
        set(value)
        {
            self.selectedDate = value
            self.selectedDateService.currentlySelectedDate = value
        }
    }
    
    //MARK: Private Properties
    private var lastRefresh : Date
    
    private let timeService : TimeService
    private let settingsService : SettingsService
    private let appLifecycleService : AppLifecycleService
    private var selectedDateService : SelectedDateService
    
    private var selectedDate : Date

    //MARK: Initializers
    init(timeService: TimeService,
         settingsService: SettingsService,
         editStateService: EditStateService,
         appLifecycleService: AppLifecycleService,
         selectedDateService: SelectedDateService)
    {
        self.timeService = timeService
        self.appLifecycleService = appLifecycleService
        self.settingsService = settingsService
        self.selectedDateService = selectedDateService
        
        lastRefresh = timeService.now
        selectedDate = timeService.now
        
        isEditingObservable = editStateService.isEditingObservable
    }
    
    //MARK: Public Methods
    func canScroll(toDate date: Date) -> Bool
    {
        let minDate = settingsService.installDate!.ignoreTimeComponents()
        let maxDate = timeService.now.ignoreTimeComponents()
        let dateWithNoTime = date.ignoreTimeComponents()
        
        return dateWithNoTime >= minDate && dateWithNoTime <= maxDate
    }
    
    //MARK: Private Methods
    private func toDateChange(_ date: Date) -> DateChange?
    {
        if date.ignoreTimeComponents() != currentlySelectedDate
        {
            let dateChange = DateChange(newDate: date, oldDate: selectedDate)
            selectedDate = date
            
            return dateChange
        }
        
        return nil
    }
}
