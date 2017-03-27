import XCTest
import CoreLocation

import Nimble

@testable import teferi

class LocationTemporaryTimelineGeneratorTests: XCTestCase {
    
    private var trackEventService:MockTrackEventService!
    private var settingsService:MockSettingsService!
    private var smartGuessService:MockSmartGuessService!
    private var timeSlotService:MockTimeSlotService!
    
    private var locationService: MockLocationService!
    private var timeService: MockTimeService!
    
    private var locationTemporaryTimelineGenerator : LocationTemporaryTimelineGenerator!
    
    override func setUp()
    {        
        self.trackEventService = MockTrackEventService()
        self.settingsService = MockSettingsService()
        self.smartGuessService = MockSmartGuessService()
        
        self.locationService = MockLocationService()
        self.timeService = MockTimeService()
        self.timeSlotService = MockTimeSlotService(
            timeService:timeService,
            locationService:locationService
        )
        
        self.locationTemporaryTimelineGenerator = LocationTemporaryTimelineGenerator(
            trackEventService:self.trackEventService,
            settingsService:self.settingsService,
            smartGuessService:self.smartGuessService,
            timeSlotService:self.timeSlotService
        )
    }
    
    func testTheAlgorithmWillNotRunForTheFirstLocationEverReceived()
    {
        self.addStoredTimeSlot(minutesBeforeNoon: 30)
        self.settingsService.lastLocation = nil
        
        self.trackEventService.mockEvents = [
            TrackEvent.baseMockEvent
        ]
        
        let timeSlots = locationTemporaryTimelineGenerator.generateTemporaryTimeline()

        expect(timeSlots.count).to(equal(0))
    }
    
    func testTheAlgorithmWillRunForTheSecondLocationEvenIfNotLastLocationExists()
    {
        self.addStoredTimeSlot(minutesBeforeNoon: 30)
        self.settingsService.lastLocation = nil
        
        self.trackEventService.mockEvents = [
            TrackEvent.baseMockEvent,
            TrackEvent.baseMockEvent.delay(hours:20).offset(meters: 300),
        ]
        
        let timeSlots = locationTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        expect(timeSlots.count).to(beGreaterThan(0))
    }
    
    func testTheAlgorithmWillNotRunIfTheNewLocationIsOlderThanTheLastLocationReceived()
    {
        self.addStoredTimeSlot(minutesBeforeNoon: 30)

        let oldLocation = CLLocation.baseLocation.offset(.north, meters: 350, seconds:8*60)
        let newLocation = CLLocation.baseLocation.offset(.north, meters: 650, seconds:-8*60)
        
        self.settingsService.lastLocation = oldLocation
        
        self.trackEventService.mockEvents = [
            Location.asTrackEvent(Location(fromCLLocation: newLocation))
        ]
        
        let timeSlots = locationTemporaryTimelineGenerator.generateTemporaryTimeline()

        expect(timeSlots.count).to(equal(0))
    }
    
    func testTheAlgorithmIgnoresInvalidLocationsAndKeepsValidOnes()
    {
        self.addStoredTimeSlot(minutesBeforeNoon: 30)
        self.settingsService.lastLocation = nil

        let locationA = CLLocation.baseLocation.offset(.north, meters: 400).with(accuracy: 50)
        let eventA = Location.asTrackEvent(Location(fromCLLocation: locationA))
        self.trackEventService.mockEvents = [
            eventA,
            eventA.delay(minutes: 30).offset(meters: 80), //Should ignore this but keep the 1st (more accurate) and last
            eventA.delay(minutes: 60).offset(meters: 160)
        ]
        
        let timeSlots = locationTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        // No lastLocation in settings, two updates -> Should create at least one TS.
        expect(timeSlots.count).to(beGreaterThan(0))
    }
    
    func testTheAlgorithmDetectsACommuteIfMultipleEntriesHappenInAShortPeriodOfTime()
    {
        self.addStoredTimeSlot(minutesBeforeNoon: 30)

        self.trackEventService.mockEvents = [
            TrackEvent.baseMockEvent.offset(meters: 200),
            TrackEvent.baseMockEvent.delay(minutes: 15).offset(meters: 400),
            TrackEvent.baseMockEvent.delay(hours:1).offset(meters: 600),
        ]
        
        let timeSlots = locationTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        let firstTimeSlot = timeSlots[0]
        expect(firstTimeSlot.category).to(equal(Category.commute))
    }
    
    func testTheAlgorithmDoesChangeTheTimeSlotToCommute()
    {
        self.addStoredTimeSlot(minutesBeforeNoon: 30)

        let firstEvent = TrackEvent.baseMockEvent.delay(hours: 1).offset(meters: 200)

        self.trackEventService.mockEvents = [
            firstEvent,
            firstEvent.delay(minutes: 15).offset(meters: 400)
        ]
        
        let timeSlots = locationTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        let firstTimeSlot = timeSlots[0]
        expect(firstTimeSlot.category).to(equal(Category.commute))
    }
    
    func testTheAlgorithmCreatesNewTimeSlotWhenANewUpdateComesAfterAWhile()
    {
        self.addStoredTimeSlot(minutesBeforeNoon: 30)

        let location = CLLocation.baseLocation.offset(.north, meters: 350)
        let secondEvent = Location.asTrackEvent(Location(fromCLLocation: location))
        
        self.trackEventService.mockEvents = [
            secondEvent
        ]
        
        let timeSlots = locationTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        expect(timeSlots.count).to(equal(1))
        expect(timeSlots.last!.start).to(equal(location.timestamp))
    }
    
    func testTheAlgorithmDoesNotCreateNewTimeSlotsUntilItDetectsTheUserBeingIdleForAWhile()
    {
        self.addStoredTimeSlot()

        let delays:[Double] = [45, 40, 50, 90, 110, 120]
        
        let dates = delays.map {
            return Date.noon.addingTimeInterval($0 * 60.0)
        }
        
        self.trackEventService.mockEvents = delays.map {
            TrackEvent.baseMockEvent.delay(minutes:$0).offset(meters:100*$0)
        }
        
        let timeSlots = locationTemporaryTimelineGenerator.generateTemporaryTimeline()
        let commutesDetected = timeSlots.filter { $0.category == .commute }
        
        expect(timeSlots.count).to(equal(3))
        expect(commutesDetected.count).to(equal(2))
        expect(timeSlots[0].start).to(equal(dates[0]))
        expect(timeSlots[1].start).to(equal(dates[2]))
        expect(timeSlots[2].start).to(equal(dates[3]))
    }
    
    func testTheAlgorithmDoesNotCreateTimeSlotsFromLocationUpdatesInSimilarLocation()
    {
        self.addStoredTimeSlot(minutesBeforeNoon: 30)

        self.trackEventService.mockEvents = [
            TrackEvent.baseMockEvent.delay(hours: 1).offset(meters: 400),
            TrackEvent.baseMockEvent.delay(hours: 1).offset(meters: 20),
            TrackEvent.baseMockEvent.delay(hours: 1).offset(meters: 30)
        ]
        
        let timeSlots = locationTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        expect(timeSlots.count).to(equal(1))
    }
    
    func testTheAlgorithmDoesNotCreateTimeSlotsFromLocationUpdatesInSimilarLocationToTheStoredOne()
    {
        self.addStoredTimeSlot(minutesBeforeNoon: 30)
        
        self.trackEventService.mockEvents = [
            TrackEvent.baseMockEvent.delay(hours: 1).offset(meters: 10)
        ]
        
        let timeSlots = locationTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        expect(timeSlots.count).to(equal(0))
    }
    
    func testTheAlgorithmDoesNotDetectCommuteFromLocationUpdatesInSimilarLocation()
    {
        self.addStoredTimeSlot(minutesBeforeNoon: 30)
        
        let firstEvent = TrackEvent.baseMockEvent.delay(hours:1).offset(meters: 200)
        
        self.trackEventService.mockEvents = [
            firstEvent,
            firstEvent.delay(minutes: 15).offset(meters: 20)
        ]
        
        let timeSlots = locationTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        expect(timeSlots.count).to(equal(1))
        expect(timeSlots[0].category).to(equal(Category.unknown))
    }
    
    func testTheAlgorithmDoesNotTouchLastKnownLocationFromLocationUpdatesInSimilarLocation()
    {
        self.addStoredTimeSlot(minutesBeforeNoon: 30)
        self.settingsService.setLastLocation(CLLocation.baseLocation)
        let firstEvent = TrackEvent.baseMockEvent.delay(minutes: 35).offset(meters: 10)
        
        self.trackEventService.mockEvents = [
            firstEvent
        ]
        
        let _ = locationTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        let lastLocation = self.settingsService.lastLocation!
        let baseLocation = CLLocation.baseLocation
        
        expect(lastLocation.coordinate.latitude).to(equal(baseLocation.coordinate.latitude))
        expect(lastLocation.coordinate.longitude).to(equal(baseLocation.coordinate.longitude))
        expect(lastLocation.timestamp).to(equal(baseLocation.timestamp))
    }
    
    func testAlgorithmAsksForSmartGuessWithCorrectLocation()
    {
        self.addStoredTimeSlot()

        let location = CLLocation.baseLocation.offset(.north, meters: 200, seconds: 60*30)
        
        self.trackEventService.mockEvents = [
            Location.asTrackEvent(Location(fromCLLocation: location))
        ]
        
        let _ = locationTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        expect(self.smartGuessService.locationsAskedFor.count).to(equal(1))

        let askedForLocation = self.smartGuessService.locationsAskedFor[0]

        expect(askedForLocation.coordinate.latitude).to(equal(location.coordinate.latitude))
        expect(askedForLocation.coordinate.longitude).to(equal(location.coordinate.longitude))
        expect(askedForLocation.timestamp).to(equal(location.timestamp))
    }
    
    func testTimeSlotGetsUnknownCategoryIfNoSmartGuessExists()
    {
        
        self.addStoredTimeSlot(minutesBeforeNoon: 30)
        
        self.smartGuessService.smartGuessToReturn = nil

        self.trackEventService.mockEvents = [
            TrackEvent.baseMockEvent.offset(meters:200).delay(minutes:30)
        ]
        
        let timeSlots = locationTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        expect(timeSlots.count).to(equal(1))
        expect(timeSlots[0].category).to(equal(Category.unknown))
    }
    
    func testTimeSlotGetsCorrectCategoryIfSmartGuessExists()
    {
        self.addStoredTimeSlot(minutesBeforeNoon: 30)
        
        self.smartGuessService.smartGuessToReturn = SmartGuess(
            withId: 0, category: .food, location: CLLocation(), lastUsed: Date.midnight)
        
        self.trackEventService.mockEvents = [
            TrackEvent.baseMockEvent.delay(hours: 1).offset(meters: 300)
        ]
        
        let timeSlots = locationTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        expect(timeSlots.count).to(equal(1))
        expect(timeSlots[0].category).to(equal(Category.food))
        
    }
    
    private func addStoredTimeSlot(minutesBeforeNoon:TimeInterval = 0)
    {
        let date = Date.noon.addingTimeInterval(-60 * minutesBeforeNoon)
        self.timeSlotService.addTimeSlot(withStartTime: date,
                                         category: .family,
                                         categoryWasSetByUser: false,
                                         tryUsingLatestLocation: false)
        
        let baseLocation =  CLLocation(coordinate: CLLocation.baseLocation.coordinate,
                                       altitude: CLLocation.baseLocation.altitude,
                                       horizontalAccuracy: CLLocation.baseLocation.horizontalAccuracy,
                                       verticalAccuracy: CLLocation.baseLocation.verticalAccuracy,
                                       timestamp: date)

        self.settingsService.setLastLocation(baseLocation)

    }
}

extension Date
{
    static var noon:Date {
        return Date.midnight.addingTimeInterval(12 * 60 * 60)
    }
    
    static var midnight:Date {
        return Date().ignoreTimeComponents()
    }
}
 
extension CLLocation
{
    static var baseLocation:CLLocation
    {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.628060, longitude: -116.848463),
            altitude:0,
            horizontalAccuracy: 100,
            verticalAccuracy: 100,
            timestamp: Date.noon
        )
    }
}

