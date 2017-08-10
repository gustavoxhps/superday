import CoreData
import UIKit
import CoreLocation

class DefaultSettingsService : SettingsService
{
    //MARK: Public Properties
    
    var installDate : Date?
    {
        return get(forKey: installDateKey)
    }
    
    var lastLocation : CLLocation?
    {
        var location : CLLocation? = nil
        
        let possibleTime = get(forKey: lastLocationDateKey) as Date?
        
        if let time = possibleTime
        {
            let latitude = getDouble(forKey: lastLocationLatKey)
            let longitude = getDouble(forKey: lastLocationLngKey)
            let horizontalAccuracy = get(forKey: lastLocationHorizontalAccuracyKey) as Double? ?? 0.0
            
            let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            location = CLLocation(coordinate: coord, altitude: 0,
                                  horizontalAccuracy: horizontalAccuracy,
                                  verticalAccuracy: 0, timestamp: time)
        }
        
        return location
    }
    
    var lastNotificationLocation : CLLocation?
    {
        guard let time = get(forKey: lastNotificationLocationDateKey) as Date? else { return nil }
        
        let latitude = getDouble(forKey: lastNotificationLocationLatKey)
        let longitude = getDouble(forKey: lastNotificationLocationLngKey)
        let horizontalAccuracy = get(forKey: lastNotificationLocationHorizontalAccuracyKey) as Double? ?? 0.0
        
        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let location = CLLocation(coordinate: coord, altitude: 0,
                                  horizontalAccuracy: horizontalAccuracy,
                                  verticalAccuracy: 0, timestamp: time)
        return location
    }
    
    var hasLocationPermission : Bool
    {
        guard CLLocationManager.locationServicesEnabled() else { return false }
        return CLLocationManager.authorizationStatus() == .authorizedAlways
    }
    
    var hasHealthKitPermission : Bool
    {
        return getBool(forKey: healthKitPermissionKey)
    }
    
    var hasNotificationPermission : Bool
    {
        let notificationSettings = UIApplication.shared.currentUserNotificationSettings
        return notificationSettings?.types.contains([.alert, .badge]) ?? false
    }
    
    var lastAskedForLocationPermission : Date?
    {
        return get(forKey: lastAskedForLocationPermissionKey)
    }
    
    var userEverGaveLocationPermission: Bool
    {
        return getBool(forKey: userGaveLocationPermissionKey)
    }
    
    var welcomeMessageHidden : Bool
    {
        return getBool(forKey: welcomeMessageHiddenKey)
    }
    
    //MARK: Private Properties
    
    private let timeService : TimeService
    
    private let installDateKey = "installDate"
    private let lastLocationLatKey = "lastLocationLat"
    private let lastLocationLngKey = "lastLocationLng"
    private let lastLocationDateKey = "lastLocationDate"
    private let lastLocationHorizontalAccuracyKey = "lastLocationHorizongalAccuracy"
    private let lastAskedForLocationPermissionKey = "lastAskedForLocationPermission"
    private let userGaveLocationPermissionKey = "canIgnoreLocationPermission"
    private let lastHealthKitUpdateKey = "lastHealthKitUpdate"
    private let healthKitPermissionKey = "healthKitPermission"
    private let welcomeMessageHiddenKey = "welcomeMessageHidden"
    
    private let lastNotificationLocationLatKey = "lastNotificationLocationLat"
    private let lastNotificationLocationLngKey = "lastNotificationLocationLng"
    private let lastNotificationLocationDateKey = "lastNotificationLocationDate"
    private let lastNotificationLocationHorizontalAccuracyKey = "lastNotificationLocationHorizontalAccuracy"
    
    //MARK: Initialiazers
    init (timeService : TimeService)
    {
        self.timeService = timeService
    }

    //MARK: Public Methods
    func lastHealthKitUpdate(for identifier: String) -> Date
    {
        let key = lastHealthKitUpdateKey + identifier
        
        guard let lastUpdate : Date = get(forKey: key)
        else
        {
            let initialDate = timeService.now
            setLastHealthKitUpdate(for: identifier, date: initialDate)
            return initialDate
        }
        
        return lastUpdate
    }
    
    func setLastHealthKitUpdate(for identifier: String, date: Date)
    {
        let key = lastHealthKitUpdateKey + identifier
        set(date, forKey: key)
    }
    
    func setInstallDate(_ date: Date)
    {
        guard installDate == nil else { return }
        
        set(date, forKey: installDateKey)
    }
    
    func setLastLocation(_ location: CLLocation)
    {
        set(location.timestamp, forKey: lastLocationDateKey)
        set(location.coordinate.latitude, forKey: lastLocationLatKey)
        set(location.coordinate.longitude, forKey: lastLocationLngKey)
        set(location.horizontalAccuracy, forKey: lastLocationHorizontalAccuracyKey)
    }
    
    func setLastNotificationLocation(_ location: CLLocation)
    {
        set(location.timestamp, forKey: lastNotificationLocationDateKey)
        set(location.coordinate.latitude, forKey: lastNotificationLocationLatKey)
        set(location.coordinate.longitude, forKey: lastNotificationLocationLngKey)
        set(location.horizontalAccuracy, forKey: lastNotificationLocationHorizontalAccuracyKey)
    }
    
    func setLastAskedForLocationPermission(_ date: Date)
    {
        set(date, forKey: lastAskedForLocationPermissionKey)
    }
    
    func setUserGaveLocationPermission()
    {
        set(true, forKey: userGaveLocationPermissionKey)
    }
    
    func setUserGaveHealthKitPermission()
    {
        set(true, forKey: healthKitPermissionKey)
    }
    
    func setWelcomeMessageHidden()
    {
        set(true, forKey: welcomeMessageHiddenKey)
    }
    
    // MARK: Private Methods
    private func get<T>(forKey key: String) -> T?
    {
        return UserDefaults.standard.object(forKey: key) as? T
    }
    private func getDouble(forKey key: String) -> Double
    {
        return UserDefaults.standard.double(forKey: key)
    }
    private func getBool(forKey key: String) -> Bool
    {
        return UserDefaults.standard.bool(forKey: key)
    }
    
    private func set(_ value: Date?, forKey key: String)
    {
        UserDefaults.standard.set(value, forKey: key)
    }
    private func set(_ value: Double, forKey key: String)
    {
        UserDefaults.standard.set(value, forKey: key)
    }
    private func set(_ value: Bool, forKey key: String)
    {
        UserDefaults.standard.set(value, forKey: key)
    }
    
}
