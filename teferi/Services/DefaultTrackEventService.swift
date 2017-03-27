import Foundation
import RxSwift

class DefaultTrackEventService : TrackEventService
{
    private let disposeBag = DisposeBag()
    private let eventSources : [EventSource]
    private let loggingService : LoggingService
    private let persistencyService : BasePersistencyService<TrackEvent>
    
    // MARK: Initializers
    init(loggingService: LoggingService, persistencyService: BasePersistencyService<TrackEvent>, withEventSources eventSources: EventSource...)
    {
        self.eventSources = eventSources
        self.loggingService = loggingService
        self.persistencyService = persistencyService

        let observables = eventSources.map { $0.eventObservable }
        Observable.from(observables)
            .merge()
            .subscribe(onNext: self.persistData)
            .addDisposableTo(disposeBag)
    }
    
    func getEvents() -> [ TrackEvent ]
    {
        return self.persistencyService.get()
    }
    
    func clearAllData()
    {
        self.persistencyService.delete()
    }
    
    private func persistData(event: TrackEvent)
    {
        if persistencyService.create(event) { return }
            
        self.loggingService.log(withLogLevel: .error, message: "Failed to log event data \(event)")
    }
}
