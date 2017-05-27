import XCTest
import UserNotifications
import Nimble
import CoreLocation
@testable import teferi

class TrackEventServiceTests : XCTestCase
{
    private var trackEventService : DefaultTrackEventService!
    
    private var loggingService : MockLoggingService!
    private var locationService : MockLocationService!
    private var healthKitService : MockHealthKitService!
    private var persistencyService : BasePersistencyService<TrackEvent>!
    
    override func setUp()
    {
        loggingService = MockLoggingService()
        locationService = MockLocationService()
        healthKitService = MockHealthKitService()
        persistencyService = TrackEventPersistencyService(loggingService: loggingService,
                                                               locationPersistencyService: MockPersistencyService<Location>(),
                                                               healthSamplePersistencyService: MockPersistencyService<HealthSample>())
        
        trackEventService = DefaultTrackEventService(loggingService: loggingService,
                                                          persistencyService: persistencyService,
                                                          withEventSources: locationService,
                                                                            healthKitService)
    }
    
    func testNewEventsGetPersistedByTheTrackEventService()
    {
        let sample = HealthSample(withIdentifier: "something", startTime: Date(), endTime: Date(), value: nil)
        
        locationService.sendNewTrackEvent(CLLocation())
        locationService.sendNewTrackEvent(CLLocation())
        healthKitService.sendNewTrackEvent(sample)
        locationService.sendNewTrackEvent(CLLocation())
        healthKitService.sendNewTrackEvent(sample)
        
        let persistedEvents = trackEventService.getEventData(ofType: Location.self)
        expect(persistedEvents.count).to(equal(3))
    }
}
