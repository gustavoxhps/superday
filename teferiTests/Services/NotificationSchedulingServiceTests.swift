import Foundation
import XCTest
import CoreLocation
import Nimble
@testable import teferi

class NotificationSchedulingServiceTests : XCTestCase
{
    private let baseCoordinates = CLLocationCoordinate2D(latitude: 37.628060, longitude: -116.848463)
    private let defaultMovementSpeed = 100.0 // (meters/minute)
    
    private var midnight : Date!
    private var noon : Date!
    
    private var timeService : MockTimeService!
    private var loggingService : MockLoggingService!
    private var settingsService : MockSettingsService!
    private var locationService : MockLocationService!
    private var smartGuessService : MockSmartGuessService!
    private var appLifecycleService : MockAppLifecycleService!
    private var notificationService : MockNotificationService!
    
    private var schedulingService : NotificationSchedulingService!
    
    override func setUp()
    {
        midnight = Date().ignoreTimeComponents()
        noon = midnight.addingTimeInterval(12 * 60 * 60)
        
        timeService = MockTimeService()
        loggingService = MockLoggingService()
        settingsService = MockSettingsService()
        locationService = MockLocationService()
        smartGuessService = MockSmartGuessService()
        appLifecycleService = MockAppLifecycleService()
        notificationService = MockNotificationService()
        
        timeService.mockDate = noon
        
        schedulingService = NotificationSchedulingService(timeService: timeService,
                                                               settingsService: settingsService,
                                                               locationService: locationService,
                                                               smartGuessService: smartGuessService,
                                                               notificationService: notificationService)
        
        appLifecycleService.publish(.movedToBackground)
    }
    
    func testTheTestHelpersCalculateLocationDifferencesCorrectly()
    {
        let close = 100.0
        let far = 123_456.0
        let expectedAccuracy = 1.0 / 1000.0
        
        let baseLocation = getLocation(withTimestamp: noon, metersFromOrigin: 0)
        let closeLocation = getLocation(withTimestamp: noon, metersFromOrigin: close)
        let farLocation = getLocation(withTimestamp: noon, metersFromOrigin: far)
        let oppositeLocation = getLocation(withTimestamp: noon, metersFromOrigin: -far)
        
        expect(closeLocation.distance(from: baseLocation)).to(beCloseTo(close, within: close * expectedAccuracy))
        expect(farLocation.distance(from: baseLocation)).to(beCloseTo(far, within: far * expectedAccuracy))
        expect(oppositeLocation.distance(from: baseLocation)).to(beCloseTo(far, within: far * expectedAccuracy))
    }
    
    func testTheTestHelpersCreateLocationsBasedOnDefaultSpeed()
    {
        let minutes = 20
        let meters = Double(minutes) * defaultMovementSpeed
        let accuracy = 1.0 / 1000.0
        
        let baseLocation = getLocation(withTimestamp: noon)
        let futureLocation = getLocation(withTimestamp: getDate(minutesPastNoon: minutes))
        
        expect(futureLocation.distance(from: baseLocation)).to(beCloseTo(meters, within: meters * accuracy))
    }
    
    func testTheAlgorithmReschedulesNotificationsOnCommute()
    {
        setupFirstTimeSlotAndLastLocation(minutesBeforeNoon: 15)
        
        let location = getLocation(withTimestamp: noon)
        locationService.sendNewTrackEvent(location)
        
        expect(self.notificationService.cancellations).to(equal(1))
        expect(self.notificationService.schedulings).to(equal(1))
        expect(self.notificationService.scheduledNotifications).to(equal(1))
    }
    
    func testTheAlgorithmReeschedulesNotificationsOnNonCommute()
    {
        setupFirstTimeSlotAndLastLocation(minutesBeforeNoon: 30)
        
        let location = getLocation(withTimestamp: noon)
        locationService.sendNewTrackEvent(location)
        
        expect(self.notificationService.cancellations).to(equal(1))
        expect(self.notificationService.schedulings).to(equal(1))
        expect(self.notificationService.scheduledNotifications).to(equal(1))
    }
    
    func testTheAlgorithmDoesNotTouchNotificationsFromLocationUpdatesInSimilarLocation()
    {
        setupFirstTimeSlotAndLastLocation(minutesBeforeNoon: 0)
        
        let location = getLocation(withTimestamp: getDate(minutesPastNoon: 30), metersFromOrigin: 20)
        locationService.sendNewTrackEvent(location)
        
        expect(self.notificationService.cancellations).to(equal(0))
        expect(self.notificationService.schedulings).to(equal(0))
    }
    
    func testTheAlgorithmDoesNotTouchLastKnownLocationFromLocationUpdatesInSimilarLocation()
    {
        setupFirstTimeSlotAndLastLocation(minutesBeforeNoon: 0)
        
        let initialLastLocation = settingsService.lastNotificationLocation!
        
        let location = getLocation(withTimestamp: getDate(minutesPastNoon: 30), metersFromOrigin: 20)
        locationService.sendNewTrackEvent(location)
        
        expect(self.settingsService.lastNotificationLocation).to(equal(initialLastLocation))
    }
    
    func testNotificationIsCancelledIfSmartGuessExists()
    {
        setupFirstTimeSlotAndLastLocation(minutesBeforeNoon: 30)
        smartGuessService.smartGuessToReturn = SmartGuess(
            withId: 0, category: .food, location: CLLocation(), lastUsed: midnight)
        
        let location = getLocation(withTimestamp: noon)
        locationService.sendNewTrackEvent(location)
        
        expect(self.notificationService.cancellations).to(equal(1))
        expect(self.notificationService.schedulings).to(equal(0))
    }
    
    // Helper methods
    @discardableResult func setupFirstTimeSlotAndLastLocation(minutesBeforeNoon : Int,
                                                              metersFromOrigin: Double? = nil,
                                                              horizontalAccuracy: Double = 20)
    {
        let date = getDate(minutesPastNoon: -minutesBeforeNoon)
        let location = getLocation(withTimestamp: date, metersFromOrigin: metersFromOrigin, horizontalAccuracy: horizontalAccuracy)
        settingsService.setLastNotificationLocation(location)
    }
    
    func getDate(minutesPastNoon minutes: Int) -> Date
    {
        return noon
            .addingTimeInterval(Double(minutes * 60))
    }
    
    func getLocation(withTimestamp date: Date) -> CLLocation
    {
        return getLocation(withTimestamp: date, horizontalAccuracy: 0)
    }
    
    func getLocation(withTimestamp date: Date, metersFromOrigin: Double?, horizontalAccuracy: Double) -> CLLocation
    {
        guard let meters = metersFromOrigin else
        {
            return getLocation(withTimestamp: date, horizontalAccuracy: horizontalAccuracy)
        }
        
        return getLocation(withTimestamp: date, metersFromOrigin: meters, horizontalAccuracy: horizontalAccuracy)
    }
    
    func getLocation(withTimestamp date: Date, horizontalAccuracy: Double) -> CLLocation
    {
        let metersPerSecond = defaultMovementSpeed / 60.0
        let secondsSinceNoon = date.timeIntervalSince(noon)
        let metersOffset = secondsSinceNoon * metersPerSecond
        
        return getLocation(withTimestamp: date, metersFromOrigin: metersOffset, horizontalAccuracy: horizontalAccuracy)
    }
    
    func getLocation(withTimestamp date: Date, metersFromOrigin distance: Double, horizontalAccuracy: Double = 20) -> CLLocation
    {
        let coordinates = baseCoordinates.offset(.north, meters: distance)
        
        return CLLocation(coordinate: coordinates,
                          altitude: 0,
                          horizontalAccuracy: horizontalAccuracy,
                          verticalAccuracy: 0,
                          timestamp: date)
    }
}
