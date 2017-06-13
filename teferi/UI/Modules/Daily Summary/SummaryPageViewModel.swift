import Foundation
import RxSwift

class SummaryPageViewModel
{
    // MARK: Public Properties
    var currentlySelectedDate : Date
    {
        get { return self.selectedDate.value.ignoreTimeComponents() }
        set(value)
        {
            self.selectedDate.value = value
            self.canMoveForwardSubject.onNext(canScroll(toDate: selectedDate.value.add(days: 1)))
            self.canMoveBackwardSubject.onNext(canScroll(toDate: selectedDate.value.add(days: -1)))
        }
    }
    
    var dateObservable : Observable<String>
    {
        return selectedDate
            .asObservable()
            .map {
                let dateformater = DateFormatter()
                dateformater.dateFormat = "EEE, dd MMM"
                return dateformater.string(from: $0)
        }
    }

    // MARK: Private Properties
    private var selectedDate = Variable<Date>(Date())
    
    private let canMoveForwardSubject = PublishSubject<Bool>()
    private(set) lazy var canMoveForwardObservable : Observable<Bool> =
    {
        return self.canMoveForwardSubject.asObservable()
    }()
    private let canMoveBackwardSubject = PublishSubject<Bool>()
    private(set) lazy var canMoveBackwardObservable : Observable<Bool> =
    {
        return self.canMoveBackwardSubject.asObservable()
    }()
    
    private let settingsService: SettingsService
    private let timeService: TimeService
    
    // MARK: Initializer
    init(date: Date,
         timeService: TimeService,
         settingsService: SettingsService)
    {
        selectedDate.value = date
        self.settingsService = settingsService
        self.timeService = timeService
    }
    
    // MARK: Methods
    func canScroll(toDate date: Date) -> Bool
    {
        let minDate = settingsService.installDate!.ignoreTimeComponents()
        let maxDate = timeService.now.ignoreTimeComponents()
        let dateWithNoTime = date.ignoreTimeComponents()
        
        return dateWithNoTime >= minDate && dateWithNoTime <= maxDate
    }
}
