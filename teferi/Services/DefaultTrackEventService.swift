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

        eventSources
            .forEach(self.subscribeToEvents)
    }
    
    func getEvents() -> [ TrackEvent ]
    {
        return self.persistencyService.get()
    }
    
    func clearAllData()
    {
        self.persistencyService.delete()
    }
    
    private func subscribeToEvents(eventSource: EventSource)
    {
        eventSource
            .eventObservable
            .subscribe(onNext: self.persistData)
            .addDisposableTo(disposeBag)
    }
    
    private func persistData(event: TrackEvent)
    {
        if persistencyService.create(event) { return }
            
        self.loggingService.log(withLogLevel: .error, message: "Failed to log event data \(event)")
    }
}
