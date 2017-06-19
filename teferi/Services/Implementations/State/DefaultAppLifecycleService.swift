import RxSwift

class DefaultAppLifecycleService : AppLifecycleService
{
    let lifecycleEventObservable : Observable<LifecycleEvent>
    private let lifecycleSubject = PublishSubject<LifecycleEvent>()

    //MARK: Initializers
    init()
    {
        lifecycleEventObservable = lifecycleSubject
                                    .asObservable()
                                    .distinctUntilChanged()
    }
    
    func publish(_ event: LifecycleEvent)
    {
        lifecycleSubject
            .on(.next(event))
    }
}
