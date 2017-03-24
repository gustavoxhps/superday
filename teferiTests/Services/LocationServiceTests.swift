import XCTest
@testable import teferi
import Nimble
import RxSwift
import RxTest
import CoreLocation

class LocationServiceTests: XCTestCase {
    
    private let baseLocation = CLLocation(latitude: 41.9754219072948, longitude: -71.0230522245947)
    
    var locationService:DefaultLocationService!
    
    private var logginService : MockLoggingService!
    private var settingsService : MockSettingsService!
    private var locationManager : MockCLLocationManager!
    private var accurateLocationManager : MockCLLocationManager!
    
    private var observer : TestableObserver<TrackEvent>!
    private var scheduler : TestScheduler!
    
    private var disposeBag = DisposeBag()
    
    override func setUp()
    {
        super.setUp()
        
        self.logginService = MockLoggingService()
        self.settingsService = MockSettingsService()
        self.locationManager = MockCLLocationManager()
        self.accurateLocationManager = MockCLLocationManager()
        
        scheduler = TestScheduler(initialClock:0)
        
        locationService = DefaultLocationService(
            loggingService: self.logginService,
            locationManager: self.locationManager,
            accurateLocationManager: self.accurateLocationManager,
            timeoutScheduler:scheduler)
     
        observer = scheduler.createObserver(TrackEvent.self)
        locationService.eventObservable
            .subscribe(observer)
            .addDisposableTo(disposeBag)

    }
    
    override func tearDown()
    {
        self.logginService = nil
        self.locationManager = nil
        self.accurateLocationManager = nil
        
        self.locationService = nil
        
        super.tearDown()
    }
    
    func testCallingStartStartsAccurateTracking() {
        
        locationService.startLocationTracking()
        
        expect(self.accurateLocationManager.updatingLocation).to(beTrue())
        expect(self.accurateLocationManager.monitoringSignificantLocationChanges).to(beFalse())
        
    }
    
    func testCallingStartDoesntStartSignificantLocationTracking() {
        
        locationService.startLocationTracking()
        
        expect(self.locationManager.updatingLocation).to(beFalse())
        expect(self.locationManager.monitoringSignificantLocationChanges).to(beFalse())
        
    }
    
    func testOnlyMostAccurateLocationGetsForwarded()
    {
        let locations = [
            baseLocation.randomOffset(withAccuracy:200),
            baseLocation.randomOffset(withAccuracy: 20),
            baseLocation.randomOffset(withAccuracy: 200)
            ]
        
        locationService.startLocationTracking()
        accurateLocationManager.sendLocations(locations)
        
        scheduler.start()
        
        let expectedEvents = [next(0, TrackEvent.toTrackEvent(locations[1]))]
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    func testAfterTimeLimitItStartsSignificantLocationTracking()
    {
        locationService.startLocationTracking()
        
        accurateLocationManager.sendLocations([baseLocation.randomOffset(withAccuracy: 200)])
        
        var seconds = 3
        scheduler.scheduleAt(seconds) {[unowned self] in
            self.accurateLocationManager.sendLocations([self.baseLocation.randomOffset(withAccuracy: 200)])
        }
        seconds += Int(Constants.maxGPSTime)
        scheduler.scheduleAt(seconds) {[unowned self] in
            self.accurateLocationManager.sendLocations([self.baseLocation.randomOffset(withAccuracy: 200)])
        }
        
        scheduler.start()
        
        expect(self.accurateLocationManager.updatingLocation).to(beFalse())
        expect(self.locationManager.monitoringSignificantLocationChanges).to(beTrue())
    }
    
    func testIfGPSLocationIsAccurateSwitchToSignificantLocationTracking()
    {
        locationService.startLocationTracking()
        
        accurateLocationManager.sendLocations([
                baseLocation.randomOffset(withAccuracy: 300),
                baseLocation.randomOffset(withAccuracy: Constants.gpsAccuracy - 5)
                ])
        
        scheduler.start()
        
        expect(self.accurateLocationManager.updatingLocation).to(beFalse())
        expect(self.locationManager.monitoringSignificantLocationChanges).to(beTrue())
    }
    
    func testAfterGPSSignificantLocationUpdatesGetForwarded()
    {
        locationService.startLocationTracking()
        
        let locations = [
            baseLocation.randomOffset(withAccuracy: 20),
            baseLocation.randomOffset(withAccuracy: 10),
            baseLocation.randomOffset(withAccuracy: 150)
        ]
     
        self.accurateLocationManager.sendLocations([baseLocation.randomOffset(withAccuracy: 200)])
        self.accurateLocationManager.sendLocations([locations[0]])
        self.locationManager.sendLocations([locations[1]])
        self.locationManager.sendLocations([locations[2]])
        
        scheduler.start()
        
        expect(self.accurateLocationManager.updatingLocation).to(beFalse())
        expect(self.locationManager.monitoringSignificantLocationChanges).to(beTrue())

        let recordedLocations = observer.events.map({ $0.value })
        let expectedLocations = locations.map(TrackEvent.toTrackEvent).map { Event.next($0) }
        XCTAssertEqual(recordedLocations, expectedLocations)
    }
    
    func testFiltersOutInvalidLocations()
    {
        locationService.startLocationTracking()
        accurateLocationManager.sendLocations([self.baseLocation.randomOffset(withAccuracy: 20)])
        
        let locations = [
            baseLocation.randomOffset(withAccuracy: 200),
            baseLocation.randomOffset(withAccuracy: Constants.significantLocationChangeAccuracy + 10), //Filter out this one
            baseLocation.randomOffset(withAccuracy: 100),
            CLLocation(latitude: 0, longitude: 0) // And this one
        ]
        
        self.locationManager.sendLocations(locations)
        
        scheduler.start()
        
        expect(self.observer.events.count).to(equal(3))
    }
}
