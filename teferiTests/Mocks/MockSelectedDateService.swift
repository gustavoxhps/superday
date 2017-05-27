@testable import teferi
import RxSwift
import Foundation

class MockSelectedDateService : SelectedDateService
{
    // MARK: Fields
    var currentlySelectedDateVariable = Variable(Date())
    
    // MARK: Initializers
    init()
    {
        currentlySelectedDateObservable =
            currentlySelectedDateVariable
                .asObservable()
                .distinctUntilChanged({ $0.differenceInDays(toDate: $1) == 0 })
    }
    
    // MARK: Properties
    let currentlySelectedDateObservable : Observable<Date>
    var currentlySelectedDate : Date
    {
        get { return self.currentlySelectedDateVariable.value }
        set(value) { currentlySelectedDateVariable.value = value }
    }
}
