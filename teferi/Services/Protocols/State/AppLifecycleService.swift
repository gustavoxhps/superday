import RxSwift

protocol AppLifecycleService
{
    var lifecycleEventObservable : Observable<LifecycleEvent> { get }
    
    func publish(_ event: LifecycleEvent)
}

extension AppLifecycleService
{
    var movedToForegroundObservable : Observable<Void>
    {
        return self.lifecycleEventObservable
            .filter {
                guard case .movedToForeground = $0 else { return false }
                return true
            }
            .mapTo(())
    }
}
