import Foundation
import RxSwift

class RxViewModel
{
    var active : Bool = false
    {
        didSet
        {
            activeSubject.onNext(active)
        }
    }
    
    private let activeSubject : PublishSubject<Bool> = PublishSubject()
    
    var didBecomeActive : Observable<Void>
    {
        return activeSubject
            .asObservable()
            .filter { $0 }
            .mapTo(())
    }
    
    var didBecomeInactive : Observable<Void>
    {
        return activeSubject
            .asObservable()
            .filter { !$0 }
            .mapTo(())
    }
}
