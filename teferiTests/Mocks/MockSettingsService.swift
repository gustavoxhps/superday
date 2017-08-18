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
    var userEverGaveLocationPermission : Bool = false
    var didShowWelcomeMessage : Bool = true
    var welcomeMessageVisible : Bool = true

    var hasLocationPermission = true
    var hasHealthKitPermission = true
    var hasNotificationPermission = true
    
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
    
    func setInstallDate(_ date: Date)
    {
        installDate = date
    }
    
    func setLastLocation(_ location: CLLocation)
    {
        lastLocation = location
    }
    
    func setLastNotificationLocation(_ location: CLLocation)
    {
        lastNotificationLocation = location
    }
    
    func setLastAskedForLocationPermission(_ date: Date)
    {
        lastAskedForLocationPermission = date
    }
    
    func getNextSmartGuessId() -> Int
    {
        return nextSmartGuessId
    }
    
    func incrementSmartGuessId()
    {
        nextSmartGuessId += 1
    }
    
    func setUserGaveLocationPermission()
    {
        userEverGaveLocationPermission = true
    }
    
    func setUserGaveHealthKitPermission()
    {
        hasHealthKitPermission = true
    }
    
    func setWelcomeMessageShown()
    {
        didShowWelcomeMessage = true
    }
    
    func setWelcomeMessage(visible: Bool)
    {
        welcomeMessageVisible = visible
    }
    
    func canShowVotingView(forDate date: Date) -> Bool
    {
        return true
    }
    
    func didVote(forDate date: Date)
    {
        
    }
}
