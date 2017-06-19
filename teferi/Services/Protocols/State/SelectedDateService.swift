import Foundation
import RxSwift

protocol SelectedDateService
{
    var currentlySelectedDate : Date { get set }
    var currentlySelectedDateObservable : Observable<Date> { get }
}
