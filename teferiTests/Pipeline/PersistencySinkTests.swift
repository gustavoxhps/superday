import Foundation
import XCTest
import Nimble
import CoreLocation
import HealthKit
@testable import teferi

class PersistencySinkTests : XCTestCase
{
    typealias TestData = TempTimelineTestData
    
    private var noon : Date!
    private var baseSlot : TemporaryTimeSlot!

    private var persistencySink : PersistencySink!
    
    private var timeService : MockTimeService!
    private var locationService : MockLocationService!
    private var settingsService : MockSettingsService!
    private var timeSlotService : MockTimeSlotService!
    private var smartGuessService : MockSmartGuessService!
    private var trackEventService : MockTrackEventService!
    
    private func getTestData() -> [TemporaryTimeSlot]
    {
        return
            [ TestData(startOffset: 0000, endOffset: 0100),
              TestData(startOffset: 0100, endOffset: 0400),
              TestData(startOffset: 0400, endOffset: 0700),
              TestData(startOffset: 0700, endOffset: 0900),
              TestData(startOffset: 0900, endOffset: 1200),
              TestData(startOffset: 1200, endOffset: 1300),
              TestData(startOffset: 1300, endOffset: nil ) ].map(toTempTimeSlot)
    }
    
    override func setUp()
    {
        self.noon = Date().ignoreTimeComponents().addingTimeInterval(12 * 60 * 60)
        self.baseSlot = TemporaryTimeSlot(start: noon,
                                          end: nil,
                                          smartGuess: nil,
                                          category: Category.unknown,
                                          location: nil)
        
        self.timeService = MockTimeService()
        self.timeService.mockDate = noon
        
        self.locationService = MockLocationService()
        self.settingsService = MockSettingsService()
        self.timeSlotService = MockTimeSlotService(timeService: timeService, locationService: locationService)
        self.smartGuessService = MockSmartGuessService()
        self.trackEventService = MockTrackEventService()
        
        self.persistencySink = PersistencySink(settingsService: self.settingsService,
                                               timeSlotService: self.timeSlotService,
                                               smartGuessService: self.smartGuessService,
                                               trackEventService: self.trackEventService,
                                               timeService: self.timeService)
    }
    
    func testTheLastUsedLocationIsPersisted()
    {
        var data = getTestData()
        
        self.settingsService.lastLocation = nil
        
        let expectedLocation = CLLocation(latitude: 37.628060, longitude: -116.848463)
        
        data[4] = data[4].with(location: Location(fromCLLocation: CLLocation(latitude: 38.628060, longitude: -117.848463)))
        data[5] = data[5].with(location: Location(fromCLLocation: expectedLocation))
        
        self.persistencySink.execute(timeline: data)
        
        expect(self.settingsService.lastLocation).toNot(beNil())
        expect(self.settingsService.lastLocation!.coordinate.latitude).to(equal(expectedLocation.coordinate.latitude))
        expect(self.settingsService.lastLocation!.coordinate.longitude).to(equal(expectedLocation.coordinate.longitude))
    }
    
    func testUsedSmartGuessesGetUpdated()
    {
        var data = getTestData()
        
        let smartGuess = SmartGuess(withId: 0,
                                    category: .unknown,
                                    location: CLLocation(latitude: 38.628060, longitude: -117.848463),
                                    lastUsed: noon.addingTimeInterval(-500))
        
        data[5] = data[5].with(smartGuess: smartGuess)
        
        let expectedDate = data[5].start
        
        self.persistencySink.execute(timeline: data)
        
        let actualDate = self.smartGuessService.smartGuessUpdates.last!.1
        
        expect(actualDate).to(equal(expectedDate))
    }
    
    func testAllTempDataIsCleared()
    {
        self.trackEventService.mockEvents = [ TrackEvent.newLocation(location: Location(fromCLLocation: CLLocation())) ]
        
        self.persistencySink.execute(timeline: self.getTestData())
        
        expect(self.trackEventService.getEventData(ofType: Location.self).count).to(equal(0))
    }
    
    private func toTempTimeSlot(data: TestData) -> TemporaryTimeSlot
    {
        return self.baseSlot.with(start: self.date(data.startOffset),
                                  end: data.endOffset != nil ? self.date(data.endOffset!) : nil)
    }
    
    private func date(_ timeInterval: TimeInterval) -> Date
    {
        return noon.addingTimeInterval(timeInterval)
    }
    
    private func smartGuess(withCategory category: teferi.Category) -> SmartGuess
    {
        return SmartGuess(withId: 0, category: category, location: CLLocation(), lastUsed: noon)
    }
}
