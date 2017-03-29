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
        self.midnight = Date().ignoreTimeComponents()
        self.noon = self.midnight.addingTimeInterval(12 * 60 * 60)
        
        self.timeService = MockTimeService()
        self.loggingService = MockLoggingService()
        self.settingsService = MockSettingsService()
        self.locationService = MockLocationService()
        self.smartGuessService = MockSmartGuessService()
        self.appLifecycleService = MockAppLifecycleService()
        self.notificationService = MockNotificationService()
        
        self.timeService.mockDate = noon
        
        self.schedulingService = NotificationSchedulingService(timeService: self.timeService,
                                                               settingsService: self.settingsService,
                                                               locationService: self.locationService,
                                                               smartGuessService: self.smartGuessService,
                                                               notificationService: self.notificationService)
        
        self.appLifecycleService.publish(.movedToBackground)
    }
    
    func testTheTestHelpersCalculateLocationDifferencesCorrectly()
    {
        let close = 100.0
        let far = 123_456.0
        let expectedAccuracy = 1.0 / 1000.0
        
        let baseLocation = self.getLocation(withTimestamp: self.noon, metersFromOrigin: 0)
        let closeLocation = self.getLocation(withTimestamp: self.noon, metersFromOrigin: close)
        let farLocation = self.getLocation(withTimestamp: self.noon, metersFromOrigin: far)
        let oppositeLocation = self.getLocation(withTimestamp: self.noon, metersFromOrigin: -far)
        
        expect(closeLocation.distance(from: baseLocation)).to(beCloseTo(close, within: close * expectedAccuracy))
        expect(farLocation.distance(from: baseLocation)).to(beCloseTo(far, within: far * expectedAccuracy))
        expect(oppositeLocation.distance(from: baseLocation)).to(beCloseTo(far, within: far * expectedAccuracy))
    }
    
    func testTheTestHelpersCreateLocationsBasedOnDefaultSpeed()
    {
        let minutes = 20
        let meters = Double(minutes) * self.defaultMovementSpeed
        let accuracy = 1.0 / 1000.0
        
        let baseLocation = self.getLocation(withTimestamp: self.noon)
        let futureLocation = self.getLocation(withTimestamp: self.getDate(minutesPastNoon: minutes))
        
        expect(futureLocation.distance(from: baseLocation)).to(beCloseTo(meters, within: meters * accuracy))
    }
    
    func testTheAlgorithmReschedulesNotificationsOnCommute()
    {
        self.setupFirstTimeSlotAndLastLocation(minutesBeforeNoon: 15)
        
        let location = self.getLocation(withTimestamp: self.noon)
        self.locationService.setMockLocation(location)
        
        expect(self.notificationService.cancellations).to(equal(1))
        expect(self.notificationService.schedulings).to(equal(1))
        expect(self.notificationService.scheduledNotifications).to(equal(1))
    }
    
    func testTheAlgorithmReeschedulesNotificationsOnNonCommute()
    {
        self.setupFirstTimeSlotAndLastLocation(minutesBeforeNoon: 30)
        
        let location = self.getLocation(withTimestamp: self.noon)
        self.locationService.setMockLocation(location)
        
        expect(self.notificationService.cancellations).to(equal(1))
        expect(self.notificationService.schedulings).to(equal(1))
        expect(self.notificationService.scheduledNotifications).to(equal(1))
    }
    
    func testTheAlgorithmDoesNotTouchNotificationsFromLocationUpdatesInSimilarLocation()
    {
        self.setupFirstTimeSlotAndLastLocation(minutesBeforeNoon: 0)
        
        let location = self.getLocation(withTimestamp: self.getDate(minutesPastNoon: 30), metersFromOrigin: 20)
        self.locationService.setMockLocation(location)
        
        expect(self.notificationService.cancellations).to(equal(0))
        expect(self.notificationService.schedulings).to(equal(0))
    }
    
    func testTheAlgorithmDoesNotTouchLastKnownLocationFromLocationUpdatesInSimilarLocation()
    {
        self.setupFirstTimeSlotAndLastLocation(minutesBeforeNoon: 0)
        
        let initialLastLocation = self.settingsService.lastNotificationLocation!
        
        let location = self.getLocation(withTimestamp: self.getDate(minutesPastNoon: 30), metersFromOrigin: 20)
        self.locationService.setMockLocation(location)
        
        expect(self.settingsService.lastNotificationLocation).to(equal(initialLastLocation))
    }
    
    func testNotificationIsCancelledIfSmartGuessExists()
    {
        self.setupFirstTimeSlotAndLastLocation(minutesBeforeNoon: 30)
        self.smartGuessService.smartGuessToReturn = SmartGuess(
            withId: 0, category: .food, location: CLLocation(), lastUsed: self.midnight)
        
        let location = self.getLocation(withTimestamp: self.noon)
        self.locationService.setMockLocation(location)
        
        expect(self.notificationService.cancellations).to(equal(1))
        expect(self.notificationService.schedulings).to(equal(0))
    }
    
    // Helper methods
    @discardableResult func setupFirstTimeSlotAndLastLocation(minutesBeforeNoon : Int,
                                                              metersFromOrigin: Double? = nil,
                                                              horizontalAccuracy: Double = 20)
    {
        let date = self.getDate(minutesPastNoon: -minutesBeforeNoon)
        let location = self.getLocation(withTimestamp: date, metersFromOrigin: metersFromOrigin, horizontalAccuracy: horizontalAccuracy)
        self.settingsService.setLastNotificationLocation(location)
    }
    
    func getDate(minutesPastNoon minutes: Int) -> Date
    {
        return self.noon
            .addingTimeInterval(Double(minutes * 60))
    }
    
    func getLocation(withTimestamp date: Date) -> CLLocation
    {
        return self.getLocation(withTimestamp: date, horizontalAccuracy: 0)
    }
    
    func getLocation(withTimestamp date: Date, metersFromOrigin: Double?, horizontalAccuracy: Double) -> CLLocation
    {
        guard let meters = metersFromOrigin else
        {
            return self.getLocation(withTimestamp: date, horizontalAccuracy: horizontalAccuracy)
        }
        
        return self.getLocation(withTimestamp: date, metersFromOrigin: meters, horizontalAccuracy: horizontalAccuracy)
    }
    
    func getLocation(withTimestamp date: Date, horizontalAccuracy: Double) -> CLLocation
    {
        let metersPerSecond = self.defaultMovementSpeed / 60.0
        let secondsSinceNoon = date.timeIntervalSince(self.noon)
        let metersOffset = secondsSinceNoon * metersPerSecond
        
        return self.getLocation(withTimestamp: date, metersFromOrigin: metersOffset, horizontalAccuracy: horizontalAccuracy)
    }
    
    func getLocation(withTimestamp date: Date, metersFromOrigin distance: Double, horizontalAccuracy: Double = 20) -> CLLocation
    {
        let coordinates = self.baseCoordinates.offset(.north, meters: distance)
        
        return CLLocation(coordinate: coordinates,
                          altitude: 0,
                          horizontalAccuracy: horizontalAccuracy,
                          verticalAccuracy: 0,
                          timestamp: date)
    }
}
