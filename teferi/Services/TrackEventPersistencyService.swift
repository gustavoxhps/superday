import CoreLocation

class TrackEventPersistencyService : BasePersistencyService<TrackEvent>
{
    private let loggingService : LoggingService
    private let locationPersistencyService : BasePersistencyService<Location>
    
    init(loggingService: LoggingService, locationPersistencyService: BasePersistencyService<CLLocation>)
    {
        self.loggingService = loggingService
        self.locationPersistencyService = locationPersistencyService
    }
    
    override func get(withPredicate predicate: Predicate?) -> [TrackEvent]
    {
        let events = [
            self.locationPersistencyService.get(withPredicate: predicate).map(TrackEvent.toTrackEvent)
        ]
        
        return events.flatMap { $0 }
    }
    
    override func create(_ element: TrackEvent) -> Bool
    {
        switch element
        {
            case .newLocation(let location):
                return self.locationPersistencyService.create(location)
        }
    }
}
