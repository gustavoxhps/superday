import RxSwift
import Foundation

class DefaultSelectedDateService : SelectedDateService
{
    //MARK: Fields
    private let currentlySelectedDateVariable : Variable<Date>
    
    //MARK: Initializers
    init(timeService: TimeService)
    {
        currentlySelectedDateVariable = Variable(timeService.now)
        
        currentlySelectedDateObservable =
            currentlySelectedDateVariable
                .asObservable()
                .distinctUntilChanged({ $0.differenceInDays(toDate: $1) == 0 })
    }
    
    //MARK: Properties
    let currentlySelectedDateObservable : Observable<Date>
    var currentlySelectedDate : Date
    {
        get { return currentlySelectedDateVariable.value }
        set(value) { currentlySelectedDateVariable.value = value }
    }
}
