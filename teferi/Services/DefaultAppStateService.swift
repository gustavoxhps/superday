import RxSwift

class DefaultAppStateService : AppStateService
{
    //MARK: Fields
    private let appStateVariable = Variable(AppState.active)

    //MARK: Initializers
    init()
    {
        self.appStateObservable =
            self.appStateVariable
                .asObservable()
                .distinctUntilChanged()
    }
    
    //MARK: Properties
    let appStateObservable : Observable<AppState>
    
    var currentAppState : AppState
    {
        get { return self.appStateVariable.value }
        set(value) { self.appStateVariable.value = value }
    }
}
