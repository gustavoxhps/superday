import RxSwift

protocol AppLifecycleService
{
    var lifecycleEventObservable : Observable<LifecycleEvent> { get }
    
    func publish(_ event: LifecycleEvent)
}
