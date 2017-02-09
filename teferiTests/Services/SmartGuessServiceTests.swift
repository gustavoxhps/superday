@testable import teferi
import XCTest
import Foundation
import CoreLocation
import Nimble

class SmartGuessServiceTests : XCTestCase
{
    private typealias TestData = (distanceFromTarget: Double, category: teferi.Category)
    private typealias LocationAndCategory = (location: CLLocation, category: teferi.Category)
    
    private var timeService : MockTimeService!
    private var loggingService : MockLoggingService!
    private var settingsService : MockSettingsService!
    private var persistencyService : MockSmartGuessPersistencyService!
    
    private var smartGuessService : DefaultSmartGuessService!
    
    override func setUp()
    {
        self.timeService = MockTimeService()
        self.loggingService = MockLoggingService()
        self.settingsService = MockSettingsService()
        self.persistencyService = MockSmartGuessPersistencyService()
        
        
        self.smartGuessService = DefaultSmartGuessService(timeService: self.timeService,
                                                          loggingService: self.loggingService,
                                                          settingsService: self.settingsService,
                                                          persistencyService: self.persistencyService)
    }
    
    func testGuessesVeryCloseToTheLocationShouldOutweighMultipleGuessesSlightlyFurtherAway()
    {
        let targetLocation = CLLocation(latitude: 41.9754219072948, longitude: -71.0230522245947)
        
        let testInput : [TestData] =
        [
            (distanceFromTarget: 08, category: .leisure),
            (distanceFromTarget: 50, category: .work),
            (distanceFromTarget: 53, category: .leisure),
            (distanceFromTarget: 54, category: .work),
            (distanceFromTarget: 59, category: .work),
            (distanceFromTarget: 66, category: .work)
        ]
        
        self.persistencyService.smartGuesses =
            testInput
                .map(toLocation(offsetFrom: targetLocation))
                .map(toSmartGuess)
        
        let smartGuess = self.smartGuessService.get(forLocation: targetLocation)!
        
        expect(smartGuess.category).to(equal(teferi.Category.leisure))
    }
    
    func testGuessesVeryCloseToTheLocationShouldOutweighMultipleGuessesSlightlyFurtherAwayEvenWithoutExtraGuessesHelpingTheWeight()
    {
        let targetLocation = CLLocation(latitude: 41.9754219072948, longitude: -71.0230522245947)
        
        let testInput : [TestData] =
        [
            (distanceFromTarget: 08, category: .leisure),
            (distanceFromTarget: 50, category: .work),
            (distanceFromTarget: 54, category: .work),
            (distanceFromTarget: 59, category: .work),
            (distanceFromTarget: 66, category: .work)
        ]
        
        self.persistencyService.smartGuesses =
            testInput
                .map(toLocation(offsetFrom: targetLocation))
                .map(toSmartGuess)
        
        let smartGuess = self.smartGuessService.get(forLocation: targetLocation)!
        
        expect(smartGuess.category).to(equal(teferi.Category.leisure))
    }
    
    func testTheAmountOfGuessesInTheSameCategoryShouldMatterWhenComparingSimilarlyDistantGuessesEvenIfTheOutnumberedGuessIsCloser()
    {
        let targetLocation = CLLocation(latitude: 41.9754219072948, longitude: -71.0230522245947)
        
        let testInput : [TestData] =
        [
            (distanceFromTarget: 50, category: .work),
            (distanceFromTarget: 54, category: .work),
            (distanceFromTarget: 59, category: .work),
            (distanceFromTarget: 53, category: .leisure),
            (distanceFromTarget: 66, category: .work)
        ]
        
        self.persistencyService.smartGuesses =
            testInput
                .map(toLocation(offsetFrom: targetLocation))
                .map(toSmartGuess)
        
        let smartGuess = self.smartGuessService.get(forLocation: targetLocation)!
        
        expect(smartGuess.category).to(equal(teferi.Category.work))
    }
    
    func testTheAmountOfGuessesInTheSameCategoryShouldMatterWhenComparingSimilarlyDistantGuesses()
    {
        let targetLocation = CLLocation(latitude: 41.9757219072951, longitude: -71.0225522245947)
        
        let testInput : [TestData] =
        [
            (distanceFromTarget: 41, category: .work),
            (distanceFromTarget: 45, category: .work),
            (distanceFromTarget: 46, category: .work),
            (distanceFromTarget: 47, category: .leisure),
            (distanceFromTarget: 53, category: .leisure),
            (distanceFromTarget: 56, category: .work)
        ]
        
        self.persistencyService.smartGuesses =
            testInput
                .map(toLocation(offsetFrom: targetLocation))
                .map(toSmartGuess)
        
        let smartGuess = self.smartGuessService.get(forLocation: targetLocation)!
        
        expect(smartGuess.category).to(equal(teferi.Category.work))
    }
    
    private func toLocation(offsetFrom baseLocation: CLLocation) -> (TestData) -> LocationAndCategory
    {
        return { (testData: TestData) in
            
            return (baseLocation.offset(.east, meters: testData.distanceFromTarget), testData.category)
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
