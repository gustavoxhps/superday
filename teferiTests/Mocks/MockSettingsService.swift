import Foundation
import CoreLocation
@testable import teferi

class MockSettingsService : SettingsService
{
    //MARK: Properties
    var nextSmartGuessId = 0
    var installDate : Date? = Date()
    var lastInactiveDate : Date? = nil
    var lastLocation : CLLocation? = nil
    var lastNotificationLocation : CLLocation? = nil
    var lastAskedForLocationPermission : Date? = nil
    
    var hasLocationPermission = true
    var hasNotificationPermission = true
    var canIgnoreLocationPermission = false
    
    var healthKitUpdates = [String: Date]()
    
    //MARK: Methods
    func lastHealthKitUpdate(for identifier: String) -> Date
    {
        guard let dateToReturn = healthKitUpdates[identifier]
        else
        {
            return lastInactiveDate!
        }
        
        return dateToReturn
    }
    
    func setLastHealthKitUpdate(for identifier: String, date: Date)
    {
        healthKitUpdates[identifier] = date
    }
    
    func setAllowedLocationPermission()
    {
        self.canIgnoreLocationPermission = true
    }
    
    func setInstallDate(_ date: Date)
    {
        self.installDate = date
    }
    
    func setLastInactiveDate(_ date: Date?)
    {
        self.lastInactiveDate = date
    }
    
    func setLastLocation(_ location: CLLocation)
    {
        self.lastLocation = location
    }
    
    func setLastNotificationLocation(_ location: CLLocation)
    {
        self.lastNotificationLocation = location
    }
    
    func setLastAskedForLocationPermission(_ date: Date)
    {
        self.lastAskedForLocationPermission = date
    }
    
    func getNextSmartGuessId() -> Int
    {
        return self.nextSmartGuessId
    }
    
    func incrementSmartGuessId()
    {
        self.nextSmartGuessId += 1
    }
}
