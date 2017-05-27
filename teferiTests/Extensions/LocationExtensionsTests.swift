import CoreLocation
import XCTest
import Nimble

class LocationExtensionsTests : XCTestCase
{
    private let baseLocation = CLLocation(latitude: 41.9754219072948, longitude: -71.0230522245947)
    
    func testTheOffsetMethodGeneratesSufficientlyAccurateLocations()
    {
        let expectedDistance = 8.0
        let calculatedLocation = baseLocation.offset(.east, meters: expectedDistance)
        let calculatedDistance = baseLocation.distance(from: calculatedLocation)
        
        expect(calculatedDistance).to(beCloseTo(expectedDistance, within: expectedDistance * 0.01))
    }
    
    func testTheOffsetMethodGeneratesSufficientlyAccurateLocationsEvenWithChainedCalls()
    {
        let verticalOffset = 10.0
        let horizontalOffset = 5.0
        let expectedDistance = sqrt(pow(horizontalOffset, 2) + pow(verticalOffset, 2))
        
        let calculatedLocation =
            baseLocation
                .offset(.south, meters: verticalOffset)
                .offset(.east, meters: horizontalOffset)
        
        let calculatedDistance = baseLocation.distance(from: calculatedLocation)
        
        expect(calculatedDistance).to(beCloseTo(expectedDistance, within: expectedDistance * 0.01))
    }
    
    func testTheOffsetMethodGeneratesSufficientlyAccurateLocationsWhenMovingWestwardsAndNorthwards()
    {
        let verticalOffset = 10.0
        let horizontalOffset = 5.0
        let expectedDistance = sqrt(pow(horizontalOffset, 2) + pow(verticalOffset, 2))
        
        let calculatedLocation =
            baseLocation
                .offset(.north, meters: verticalOffset)
                .offset(.west, meters: horizontalOffset)
        
        let calculatedDistance = baseLocation.distance(from: calculatedLocation)
        
        expect(calculatedDistance).to(beCloseTo(expectedDistance, within: expectedDistance * 0.01))
    }
}
