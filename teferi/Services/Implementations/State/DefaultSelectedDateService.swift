import RxSwift
import Foundation

class DefaultSelectedDateService : SelectedDateService
{
    let currentlySelectedDateObservable : Observable<Date>
    var currentlySelectedDate : Date
    {
        get { return currentlySelectedDateVariable.value }
        set(value) { currentlySelectedDateVariable.value = value }
    }
    
    private let currentlySelectedDateVariable : Variable<Date>
        
    init(timeService: TimeService)
    {
        currentlySelectedDateVariable = Variable(timeService.now)
        
        currentlySelectedDateObservable =
            currentlySelectedDateVariable
                .asObservable()
                .distinctUntilChanged({ $0.differenceInDays(toDate: $1) == 0 })
    }
}
