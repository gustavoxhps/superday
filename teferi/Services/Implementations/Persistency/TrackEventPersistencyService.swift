import Darwin
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
        guard let typeName = predicate?.parameters.first as? String else { return [] }
        
        switch typeName
        {
            case String(describing: Location.self):
                return locationPersistencyService.get().map(Location.asTrackEvent)
            case String(describing: HealthSample.self):
                return healthSamplePersistencyService.get().map(HealthSample.asTrackEvent)
            default:
                return []
        }
    }
    
    override func create(_ element: TrackEvent) -> Bool
    {
        switch element
        {
            case .newLocation(let location):
                return locationPersistencyService.create(location)
            case .newHealthSample(let sample):
                return healthSamplePersistencyService.create(sample)
        }
    }
    
    override func delete(withPredicate predicate: Predicate?) -> Bool
    {
        var deleted = true
        deleted = locationPersistencyService.delete(withPredicate: predicate)
        deleted = healthSamplePersistencyService.delete(withPredicate: predicate) && deleted
        
        return deleted
    }
}
