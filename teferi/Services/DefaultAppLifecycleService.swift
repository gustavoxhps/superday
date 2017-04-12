import RxSwift

class DefaultAppLifecycleService : AppLifecycleService
{
    //MARK: Fields
    private let lifecycleSubject = PublishSubject<LifecycleEvent>()

    //MARK: Initializers
    init()
    {
        self.lifecycleEventObservable =
            self.lifecycleSubject
                .asObservable()
                .distinctUntilChanged()
    }
    
    //MARK: Properties
    let lifecycleEventObservable : Observable<LifecycleEvent>
    
    func publish(_ event: LifecycleEvent)
    {
        lifecycleSubject
            .on(.next(event))
    }
}
