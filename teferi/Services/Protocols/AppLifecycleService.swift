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
            .filter({ $0 == .movedToForeground })
            .mapTo(())
    }
    
    var notificationObservable : Observable<Void>
    {
        return self.lifecycleEventObservable
            .filter({ $0 == .receivedNotification })
            .mapTo(())
    }
}
