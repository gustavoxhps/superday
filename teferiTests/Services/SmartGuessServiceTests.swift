@testable import teferi
import XCTest
import Foundation
import CoreLocation
import Nimble

class SmartGuessServiceTests : XCTestCase
{
    private typealias TestData = (distanceFromTarget: Double, category: teferi.Category, date: Date)
    private typealias LocationAndCategory = (location: CLLocation, category: teferi.Category)
    
    private var timeService : MockTimeService!
    private var loggingService : MockLoggingService!
    private var settingsService : MockSettingsService!
    private var persistencyService : MockSmartGuessPersistencyService!
    private let date = Date()
    
    private var smartGuessService : DefaultSmartGuessService!
    
    override func setUp()
    {
        timeService = MockTimeService()
        loggingService = MockLoggingService()
        settingsService = MockSettingsService()
        persistencyService = MockSmartGuessPersistencyService()
        
        
        smartGuessService = DefaultSmartGuessService(timeService: timeService,
                                                          loggingService: loggingService,
                                                          settingsService: settingsService,
                                                          persistencyService: persistencyService)
    }
    
    func testGuessesAreReturnedWithTimestampsWithinThresholdFromLocation()
    {
        let targetLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 41.9754219072948,
                longitude: -71.0230522245947),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: date.add(days: -11))
        
        let testInput : [TestData] =
        [
            (distanceFromTarget: 50, category: .work, date: date.add(days: -1).addingTimeInterval(19400)),
            (distanceFromTarget: 50, category: .work, date: date.add(days: -2).addingTimeInterval(19400)),
            (distanceFromTarget: 50, category: .work, date: date.add(days: -3).addingTimeInterval(19400)),
            (distanceFromTarget: 50, category: .leisure, date: date.add(days: -4)),
            (distanceFromTarget: 50, category: .work, date: date.add(days: -5).addingTimeInterval(19400)),
            (distanceFromTarget: 50, category: .work, date: date.add(days: -6).addingTimeInterval(19400))
        ]
        
        persistencyService.smartGuesses =
            testInput
                .map(toLocation(offsetFrom: targetLocation))
                .map(toSmartGuess)
        
        let smartGuess = smartGuessService.get(forLocation: targetLocation)
        
        expect(smartGuess?.category).to(equal(teferi.Category.leisure))
    }
    
    func testGuessesAreNotReturnedWithTimestampsOutsideThresholdFromLocation()
    {
        let targetLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 41.9754219072948,
                longitude: -71.0230522245947),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: date.add(days: -11))
        
        let testInput : [TestData] =
            [
                (distanceFromTarget: 50, category: .work, date: date.add(days: -1).addingTimeInterval(19400)),
                (distanceFromTarget: 50, category: .work, date: date.add(days: -2).addingTimeInterval(19400)),
                (distanceFromTarget: 50, category: .work, date: date.add(days: -3).addingTimeInterval(19400)),
                (distanceFromTarget: 50, category: .leisure, date: date.add(days: -5)),
                (distanceFromTarget: 50, category: .work, date: date.add(days: -5).addingTimeInterval(19400)),
                (distanceFromTarget: 50, category: .work, date: date.add(days: -6).addingTimeInterval(19400))
        ]
        
        persistencyService.smartGuesses =
            testInput
                .map(toLocation(offsetFrom: targetLocation))
                .map(toSmartGuess)
        
        let smartGuess = smartGuessService.get(forLocation: targetLocation)
        
        expect(smartGuess?.category).to(beNil())
    }
    
    func testMultipleFarAwayGuessesCanOutweighSingleCloseGuess()
    {
        let targetLocation = CLLocation(latitude: 41.9754219072948, longitude: -71.0230522245947)
        
        let testInput : [TestData] =
            [
                (distanceFromTarget: 08, category: .leisure, date: date),
                (distanceFromTarget: 50, category: .work, date: date),
                (distanceFromTarget: 54, category: .work, date: date),
                (distanceFromTarget: 59, category: .work, date: date),
                (distanceFromTarget: 66, category: .work, date: date)
        ]
        
        persistencyService.smartGuesses =
            testInput
                .map(toLocation(offsetFrom: targetLocation))
                .map(toSmartGuess)
        
        let smartGuess = smartGuessService.get(forLocation: targetLocation)!
        
        expect(smartGuess.category).to(equal(teferi.Category.work))
    }
    
    func testGuessesVeryCloseToTheLocationShouldOutweighMultipleGuessesSlightlyFurtherAway()
    {
        let targetLocation = CLLocation(latitude: 41.9754219072948, longitude: -71.0230522245947)
        
        let testInput : [TestData] =
        [
            (distanceFromTarget: 08, category: .leisure, date: date),
            (distanceFromTarget: 50, category: .work, date: date),
            (distanceFromTarget: 53, category: .leisure, date: date),
            (distanceFromTarget: 54, category: .work, date: date),
            (distanceFromTarget: 59, category: .work, date: date),
            (distanceFromTarget: 66, category: .work, date: date)
        ]
        
        persistencyService.smartGuesses =
            testInput
                .map(toLocation(offsetFrom: targetLocation))
                .map(toSmartGuess)
        
        let smartGuess = smartGuessService.get(forLocation: targetLocation)!
        
        expect(smartGuess.category).to(equal(teferi.Category.leisure))
    }
    
    func testGuessesVeryCloseToTheLocationShouldOutweighMultipleGuessesSlightlyFurtherAwayEvenWithoutExtraGuessesHelpingTheWeight()
    {
        let targetLocation = CLLocation(latitude: 41.9754219072948, longitude: -71.0230522245947)
        
        let testInput : [TestData] =
        [
            (distanceFromTarget: 08, category: .leisure, date: date),
            (distanceFromTarget: 60, category: .work, date: date),
            (distanceFromTarget: 64, category: .work, date: date),
            (distanceFromTarget: 69, category: .work, date: date),
            (distanceFromTarget: 76, category: .work, date: date)
        ]
        
        persistencyService.smartGuesses =
            testInput
                .map(toLocation(offsetFrom: targetLocation))
                .map(toSmartGuess)
        
        let smartGuess = smartGuessService.get(forLocation: targetLocation)!
        
        expect(smartGuess.category).to(equal(teferi.Category.leisure))
    }
    
    func testTheAmountOfGuessesInTheSameCategoryShouldMatterWhenComparingSimilarlyDistantGuessesEvenIfTheOutnumberedGuessIsCloser()
    {
        let targetLocation = CLLocation(latitude: 41.9754219072948, longitude: -71.0230522245947)
        
        let testInput : [TestData] =
        [
            (distanceFromTarget: 50, category: .work, date: date),
            (distanceFromTarget: 54, category: .work, date: date),
            (distanceFromTarget: 59, category: .work, date: date),
            (distanceFromTarget: 53, category: .leisure, date: date),
            (distanceFromTarget: 66, category: .work, date: date)
        ]
        
        persistencyService.smartGuesses =
            testInput
                .map(toLocation(offsetFrom: targetLocation))
                .map(toSmartGuess)
        
        let smartGuess = smartGuessService.get(forLocation: targetLocation)!
        
        expect(smartGuess.category).to(equal(teferi.Category.work))
    }
    
    func testTheAmountOfGuessesInTheSameCategoryShouldMatterWhenComparingSimilarlyDistantGuesses()
    {
        let targetLocation = CLLocation(latitude: 41.9757219072951, longitude: -71.0225522245947)
        
        let testInput : [TestData] =
        [
            (distanceFromTarget: 41, category: .work, date: date),
            (distanceFromTarget: 45, category: .work, date: date),
            (distanceFromTarget: 46, category: .work, date: date),
            (distanceFromTarget: 47, category: .leisure, date: date),
            (distanceFromTarget: 53, category: .leisure, date: date),
            (distanceFromTarget: 56, category: .work, date: date)
        ]
        
        persistencyService.smartGuesses =
            testInput
                .map(toLocation(offsetFrom: targetLocation))
                .map(toSmartGuess)
        
        let smartGuess = smartGuessService.get(forLocation: targetLocation)!
        
        expect(smartGuess.category).to(equal(teferi.Category.work))
    }
    
    private func toLocation(offsetFrom baseLocation: CLLocation) -> (TestData) -> LocationAndCategory
    {
        return { (testData: TestData) in
            
            return (baseLocation.offset(.east, meters: testData.distanceFromTarget, timestamp: testData.date), testData.category)
        }
    }
    
    private func toSmartGuess(locationAndCategory: LocationAndCategory) -> SmartGuess
    {
        return SmartGuess(withId: 0,
                          category: locationAndCategory.category,
                          location: locationAndCategory.location,
                          lastUsed: Date())
    }
}
