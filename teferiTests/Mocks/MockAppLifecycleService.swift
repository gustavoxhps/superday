import RxSwift
@testable import teferi

class MockAppLifecycleService : AppLifecycleService
{
    //MARK: Fields
    private let lifecycleEventSubject = BehaviorSubject<LifecycleEvent>(value: .movedToForeground(fromNotification:false))
    
    //MARK: Initializers
    init()
    {
        lifecycleEventObservable = lifecycleEventSubject.asObservable()
    }
    
    //MARK: Properties
    let lifecycleEventObservable : Observable<LifecycleEvent>

    func publish(_ event: LifecycleEvent)
    {
        lifecycleEventSubject.onNext(event)
    }
}
