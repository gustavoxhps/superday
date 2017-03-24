import HealthKit
import CoreLocation

class TrackEventPersistencyService : BasePersistencyService<TrackEvent>
{
    private let loggingService : LoggingService
    private let locationPersistencyService : BasePersistencyService<Location>
    private let healthSamplePersistencyService : BasePersistencyService<HealthSample>
    
    init(loggingService: LoggingService,
         locationPersistencyService: BasePersistencyService<Location>,
         healthSamplePersistencyService: BasePersistencyService<HealthSample>)
    {
        self.loggingService = loggingService
        self.locationPersistencyService = locationPersistencyService
        self.healthSamplePersistencyService = healthSamplePersistencyService
    }
    
    override func get(withPredicate predicate: Predicate?) -> [TrackEvent]
    {
        let events = [
            self.locationPersistencyService.get(withPredicate: predicate).map(TrackEvent.toTrackEvent),
            self.healthSamplePersistencyService.get(withPredicate: predicate).map(TrackEvent.toTrackEvent)
        ]
        
        return events.flatMap { $0 }
    }
    
    override func create(_ element: TrackEvent) -> Bool
    {
        switch element
        {
            case .newLocation(let location):
                return self.locationPersistencyService.create(location)
            case .newHealthSample(let sample):
                return self.healthSamplePersistencyService.create(sample)
        }
    }
    
    override func delete(withPredicate predicate: Predicate?) -> Bool
    {
        var deleted = true
        deleted = self.locationPersistencyService.delete(withPredicate: predicate)
        deleted = self.healthSamplePersistencyService.delete(withPredicate: predicate) && deleted
        
        return deleted
    }
}
