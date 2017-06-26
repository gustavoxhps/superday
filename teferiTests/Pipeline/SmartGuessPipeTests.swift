import XCTest
import Nimble
import CoreLocation
@testable import teferi

class SmartGuessPipeTests: XCTestCase
{
    private var smartGuessService : MockSmartGuessService!
    private var pipe : SmartGuessPipe!
    
    override func setUp()
    {
        smartGuessService = MockSmartGuessService()
        pipe = SmartGuessPipe(smartGuessService: smartGuessService)
    }
    
    func testAlgorithmAsksForSmartGuessWithCorrectLocation()
    {
        let location = CLLocation.baseLocation.offset(.north, meters: 200, seconds: 60*30)
        
        let timeline = [
            TemporaryTimeSlot(location: Location(fromCLLocation: location), category: .unknown)
        ]
        
        let _ = pipe.process(timeline: timeline)
        
        expect(self.smartGuessService.locationsAskedFor.count).to(equal(1))
        
        let askedForLocation = smartGuessService.locationsAskedFor[0]
        
        expect(askedForLocation.coordinate.latitude).to(equal(location.coordinate.latitude))
        expect(askedForLocation.coordinate.longitude).to(equal(location.coordinate.longitude))
        expect(askedForLocation.timestamp).to(equal(location.timestamp))
    }
    
    func testTimeSlotGetsUnknownCategoryIfNoSmartGuessExists()
    {
        smartGuessService.smartGuessToReturn = nil
        
        let location = CLLocation.baseLocation.offset(.north, meters: 200, seconds: 60*30)
        
        let timeline = [
            TemporaryTimeSlot(location: Location(fromCLLocation: location), category: .unknown)
        ]
        
        let timeSlots = pipe.process(timeline: timeline)
        
        expect(timeSlots.count).to(equal(1))
        expect(timeSlots[0].category).to(equal(Category.unknown))
    }
    
    func testTimeSlotGetsCorrectCategoryIfSmartGuessExists()
    {
        smartGuessService.smartGuessToReturn = SmartGuess(withId: 0, category: .food, location: CLLocation(), lastUsed: Date.midnight)
        
        let location = CLLocation.baseLocation.offset(.north, meters: 200, seconds: 60*30)
        
        let timeline = [
            TemporaryTimeSlot(location: Location(fromCLLocation: location), category: .unknown)
        ]
        
        let timeSlots = pipe.process(timeline: timeline)
        
        expect(timeSlots.count).to(equal(1))
        expect(timeSlots[0].category).to(equal(Category.food))
    }
    
    func testPipeAsksForSmartGuessOnlyForUnknownSlots()
    {
        let location1 = CLLocation.baseLocation.offset(.north, meters: 200, seconds: 60*30)
        let location2 = CLLocation.baseLocation.offset(.north, meters: 400, seconds: 60*30*2)
        
        let timeline = [
            TemporaryTimeSlot(location: Location(fromCLLocation: CLLocation.baseLocation), category: .food),
            TemporaryTimeSlot(location: Location(fromCLLocation: location1), category: .unknown),
            TemporaryTimeSlot(location: Location(fromCLLocation: CLLocation.baseLocation), category: .commute),
            TemporaryTimeSlot(location: Location(fromCLLocation: location2), category: .unknown)
        ]
        
        let _ = pipe.process(timeline: timeline)
        
        expect(self.smartGuessService.locationsAskedFor.count).to(equal(2))
        
        let askedForLocation1 = smartGuessService.locationsAskedFor[0]
        let askedForLocation2 = smartGuessService.locationsAskedFor[1]
        
        expect(askedForLocation1.coordinate.latitude).to(equal(location1.coordinate.latitude))
        expect(askedForLocation1.coordinate.longitude).to(equal(location1.coordinate.longitude))
        expect(askedForLocation1.timestamp).to(equal(location1.timestamp))
        
        expect(askedForLocation2.coordinate.latitude).to(equal(location2.coordinate.latitude))
        expect(askedForLocation2.coordinate.longitude).to(equal(location2.coordinate.longitude))
        expect(askedForLocation2.timestamp).to(equal(location2.timestamp))
    }
}
