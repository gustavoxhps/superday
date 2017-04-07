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
    
    func testCallingStartStartsSignificantLocationTracking()
    {
        
        locationService.startLocationTracking()

        expect(self.locationManager.monitoringSignificantLocationChanges).to(beTrue())
        expect(self.locationManager.updatingLocation).to(beFalse())
        
    }
    
    func testCallingStartDoesntStartSignificantLocationTracking()
    {
        
        locationService.startLocationTracking()
        
        expect(self.accurateLocationManager.updatingLocation).to(beFalse())
        expect(self.accurateLocationManager.monitoringSignificantLocationChanges).to(beFalse())
        
    }
    
    func testWhenASignificantLocationChangeHappensAccurateLocationTrackingStarts()
    {
        locationService.startLocationTracking()
        
        locationManager.sendLocations([baseLocation.randomOffset(withAccuracy:200)])
        
        expect(self.accurateLocationManager.updatingLocation).to(beTrue())
        expect(self.accurateLocationManager.monitoringSignificantLocationChanges).to(beFalse())
    }
    
    func testOnlyMostAccurateLocationGetsForwarded()
    {
        let locations = [
            baseLocation.randomOffset(withAccuracy:200),
            baseLocation.randomOffset(withAccuracy: 20),
            baseLocation.randomOffset(withAccuracy: 200)
            ]
        
        locationService.startLocationTracking()
        locationManager.sendLocations([baseLocation.randomOffset(withAccuracy:200)])
        accurateLocationManager.sendLocations(locations)
        
        scheduler.start()
        
        let expectedEvents = [next(0, Location.asTrackEvent(Location(fromCLLocation: locations[1])))]
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    func testAfterTimeLimitItStartsSignificantLocationTracking()
    {
        locationService.startLocationTracking()
        
        locationManager.sendLocations([baseLocation.randomOffset(withAccuracy:200)])
        
        var seconds = 3
        scheduler.scheduleAt(seconds) {[unowned self] in
            self.accurateLocationManager.sendLocations([self.baseLocation.randomOffset(withAccuracy: Constants.gpsAccuracy + 200)]) //Not accurate enough
        }
        seconds += Int(Constants.maxGPSTime)
        scheduler.scheduleAt(seconds) {[unowned self] in
            self.accurateLocationManager.sendLocations([self.baseLocation.randomOffset(withAccuracy: Constants.gpsAccuracy - 10)]) //Accurate enough, but out of time
        }
        
        scheduler.start()
        
        expect(self.observer.events.count).to(equal(1))
        expect(self.accurateLocationManager.updatingLocation).to(beFalse())
        expect(self.locationManager.monitoringSignificantLocationChanges).to(beTrue())
    }
    
    func testIfGPSLocationIsAccurateSwitchToSignificantLocationTracking()
    {
        locationService.startLocationTracking()
        
        locationManager.sendLocations([baseLocation.randomOffset(withAccuracy:200)])

        accurateLocationManager.sendLocations([
                baseLocation.randomOffset(withAccuracy: Constants.gpsAccuracy + 10),
                baseLocation.randomOffset(withAccuracy: Constants.gpsAccuracy - 5)
                ])
        
        scheduler.start()
        
        expect(self.accurateLocationManager.updatingLocation).to(beFalse())
        expect(self.locationManager.monitoringSignificantLocationChanges).to(beTrue())
    }
    
    func testFiltersOutInvalidLocations()
    {
        locationService.startLocationTracking()
        
        let locations = [
            baseLocation.randomOffset(withAccuracy: Constants.significantLocationChangeAccuracy - 10),
            baseLocation.randomOffset(withAccuracy: Constants.significantLocationChangeAccuracy + 10), // Filter out this one
            baseLocation.randomOffset(withAccuracy: Constants.significantLocationChangeAccuracy - 1),
            CLLocation(latitude: 0, longitude: 0) // And this one
        ]
        
        locations.forEach { [unowned self] location in
            self.locationManager.sendLocations(locations)
            self.accurateLocationManager.sendLocations([self.baseLocation.randomOffset(withAccuracy:4000)]) //GPS won't replace SLC
        }
        
        
        scheduler.start()
        
        expect(self.observer.events.count).to(equal(2))
    }
    
    
    func testGPSReplacesSignificantLocationTrackingIfLessAccurate()
    {
        locationService.startLocationTracking()
        
        let location = baseLocation.randomOffset(withAccuracy: 150)
        let gpsLocation = baseLocation.randomOffset(withAccuracy: 50)
        
        locationManager.sendLocations([location])
        accurateLocationManager.sendLocations([gpsLocation])
        
        scheduler.start()
        
        let resultLocation = observer.events.last!.value.element!
        XCTAssertEqual(resultLocation, TrackEvent.newLocation(location: Location(fromCLLocation: gpsLocation)))
    }
    
    func testGPSDoesntReplaceSignificantLocationTrackingIfLessAccurate()
    {
        locationService.startLocationTracking()
        
        let location = baseLocation.randomOffset(withAccuracy: 50)
        let gpsLocation = baseLocation.randomOffset(withAccuracy: 150)
        
        locationManager.sendLocations([location])
        accurateLocationManager.sendLocations([gpsLocation])
        
        scheduler.start()
        
        let resultLocation = observer.events.last!.value.element!
        XCTAssertEqual(resultLocation, TrackEvent.newLocation(location: Location(fromCLLocation: location)))
    }
    
    func testIfGPSDoesntReturnAnythinItUsesSignificantLocationChangeValue()
    {
        locationService.startLocationTracking()
        
        let location = baseLocation.randomOffset(withAccuracy:200)
        locationManager.sendLocations([location])
        
        
        scheduler.start()
        scheduler.advanceTo(Int(Constants.maxGPSTime + 10))
        
        expect(self.observer.events.count).to(equal(1))
        let resultLocation = observer.events.last!.value.element!
        XCTAssertEqual(resultLocation, TrackEvent.newLocation(location: Location(fromCLLocation: location)))
    }
    
    func testGPSRunsEverytimeTheresANewSignificantLocationChange()
    {
        locationService.startLocationTracking()
        
        let gpsLocation = baseLocation.randomOffset(withAccuracy: 10)
        
        locationManager.sendLocations([baseLocation.randomOffset(withAccuracy: 250)])
        accurateLocationManager.sendLocations([baseLocation.randomOffset(withAccuracy: 10)])
        locationManager.sendLocations([baseLocation.randomOffset(withAccuracy: 250)])
        accurateLocationManager.sendLocations([gpsLocation])
        
        scheduler.start()
        
        let resultLocation = observer.events.last!.value.element!
        XCTAssertEqual(resultLocation, TrackEvent.newLocation(location: Location(fromCLLocation: gpsLocation)))
    }
}
