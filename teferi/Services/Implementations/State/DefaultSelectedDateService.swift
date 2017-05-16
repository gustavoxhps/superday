import RxSwift
import Foundation

class DefaultSelectedDateService : SelectedDateService
{
    //MARK: Fields
    private let currentlySelectedDateVariable : Variable<Date>
    
    //MARK: Initializers
    init(timeService: TimeService)
    {
        self.currentlySelectedDateVariable = Variable(timeService.now)
        
        self.currentlySelectedDateObservable =
            self.currentlySelectedDateVariable
                .asObservable()
                .distinctUntilChanged({ $0.differenceInDays(toDate: $1) == 0 })
    }
    
    //MARK: Properties
    let currentlySelectedDateObservable : Observable<Date>
    var currentlySelectedDate : Date
    {
        get { return self.currentlySelectedDateVariable.value }
        set(value) { self.currentlySelectedDateVariable.value = value }
    }
}
