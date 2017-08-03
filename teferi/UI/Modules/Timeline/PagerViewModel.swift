import RxSwift
import RxCocoa
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
    
    var currentlySelectedDate : Date
    {
        get { return self.selectedDate.ignoreTimeComponents() }
        set(value)
        {
            self.selectedDate = value
            self.selectedDateService.currentlySelectedDate = value
        }
    }
    
    var activitiesObservable : Driver<[Activity]>
    {
        let addedTimeSlot = timeSlotService.timeSlotCreatedObservable
            .mapTo(())
        
        let updatedTimeSlot = timeSlotService.timeSlotUpdatedObservable
            .mapTo(())
        
        let dateChage = selectedDateService.currentlySelectedDateObservable
            .mapTo(())
        
        let movedToForeground = appLifecycleService.movedToForegroundObservable
        
        return Observable.of(addedTimeSlot, updatedTimeSlot, dateChage, movedToForeground).merge()
            .startWith(())
            .map(activitiesForCurrentDate)
            .asDriver(onErrorJustReturn: [])
    }
    
    //MARK: Private Properties
    private var lastRefresh : Date
    
    private let timeService : TimeService
    private let timeSlotService : TimeSlotService
    private let settingsService : SettingsService
    private let appLifecycleService : AppLifecycleService
    private var selectedDateService : SelectedDateService
    
    private var selectedDate : Date

    //MARK: Initializers
    init(timeService: TimeService,
         timeSlotService: TimeSlotService,
         settingsService: SettingsService,
         editStateService: EditStateService,
         appLifecycleService: AppLifecycleService,
         selectedDateService: SelectedDateService)
    {
        self.timeService = timeService
        self.timeSlotService = timeSlotService
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
    
    private func activitiesForCurrentDate() -> [Activity]
    {
        return self.timeSlotService
            .getActivities(forDate: selectedDate)
            .sorted(by: { $0.duration > $1.duration })
    }
}
