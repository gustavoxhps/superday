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
    private let date = Date()
    
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
    
    func testGuessesAreReturnedWithTimestampsWithinThresholdFromLocation()
    {
        self.persistencyService.smartGuesses =
            [  ( 41.9752219072946, -71.0224522245947, teferi.Category.work, date.add(days: -1).addingTimeInterval(19400) ),
               ( 41.9753319073047, -71.0223522246947, teferi.Category.work, date.add(days: -2).addingTimeInterval(19400) ),
               ( 41.9753219072949, -71.0224522245947, teferi.Category.work, date.add(days: -3).addingTimeInterval(19400) ),
               ( 41.9754219072948, -71.0229522245947, teferi.Category.leisure, date.add(days: -4) ),
               ( 41.9754219072950, -71.0222522245947, teferi.Category.work, date.add(days: -5).addingTimeInterval(19400) ),
               ( 41.9757219072951, -71.0225522245947, teferi.Category.leisure, date.add(days: -6).addingTimeInterval(19400) )]
                .map(toLocation)
                .map(toSmartGuess)
        
        let targetLocation = self.toLocation(latLngCategory: (41.9754219072948, -71.0230522245947, nil, date.add(days: -11))).0
        
        let smartGuess = self.smartGuessService.get(forLocation: targetLocation)
        
        expect(smartGuess).notTo(beNil())
    }
    
    func testNoGuessesAreReturnedWithTimestampsFurtherThanThresholdFromLocation()
    {
        self.persistencyService.smartGuesses =
            [  ( 41.9752219072946, -71.0224522245947, teferi.Category.work, date.add(days: -1) ),
               ( 41.9753319073047, -71.0223522246947, teferi.Category.work, date.add(days: -2) ),
               ( 41.9753219072949, -71.0224522245947, teferi.Category.work, date.add(days: -3) )]
                .map(toLocation)
                .map(toSmartGuess)
        
        let targetLocation = self.toLocation(latLngCategory: (41.9754219072948, -71.0230522245947, nil, date.add(days: -5))).0
        
        let smartGuess = self.smartGuessService.get(forLocation: targetLocation)
        
        expect(smartGuess).to(beNil())
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
