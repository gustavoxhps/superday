import CoreData
import UIKit
import CoreLocation

class DefaultSettingsService : SettingsService
{
    //MARK: Fields
    private let installDateKey = "installDate"
    private let lastLocationLatKey = "lastLocationLat"
    private let lastLocationLngKey = "lastLocationLng"
    private let lastLocationDateKey = "lastLocationDate"
    private let lastLocationHorizontalAccuracyKey = "lastLocationHorizongalAccuracy"
    private let lastAskedForLocationPermissionKey = "lastAskedForLocationPermission"
    private let userGaveLocationPermissionKey = "canIgnoreLocationPermission"
    private let lastHealthKitUpdateKey = "lastHealthKitUpdate"
    
    private let lastNotificationLocationLatKey = "lastNotificationLocationLat"
    private let lastNotificationLocationLngKey = "lastNotificationLocationLng"
    private let lastNotificationLocationDateKey = "lastNotificationLocationDate"
    private let lastNotificationLocationHorizontalAccuracyKey = "lastNotificationLocationHorizontalAccuracy"
    
    //MARK: Properties
    var installDate : Date?
    {
        return self.get(forKey: self.installDateKey)
    }
    
    var lastLocation : CLLocation?
    {
        var location : CLLocation? = nil
        
        let possibleTime = self.get(forKey: self.lastLocationDateKey) as Date?
        
        if let time = possibleTime
        {
            let latitude = self.getDouble(forKey: self.lastLocationLatKey)
            let longitude = self.getDouble(forKey: self.lastLocationLngKey)
            let horizontalAccuracy = self.get(forKey: self.lastLocationHorizontalAccuracyKey) as Double? ?? 0.0
            
            let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            location = CLLocation(coordinate: coord, altitude: 0,
                                  horizontalAccuracy: horizontalAccuracy,
                                  verticalAccuracy: 0, timestamp: time)
        }
        
        return location
    }
    
    var lastNotificationLocation : CLLocation?
    {
        guard let time = self.get(forKey: self.lastNotificationLocationDateKey) as Date? else { return nil }

        let latitude = self.getDouble(forKey: self.lastNotificationLocationLatKey)
        let longitude = self.getDouble(forKey: self.lastNotificationLocationLngKey)
        let horizontalAccuracy = self.get(forKey: self.lastNotificationLocationHorizontalAccuracyKey) as Double? ?? 0.0
        
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
    
    var hasNotificationPermission : Bool
    {
        let notificationSettings = UIApplication.shared.currentUserNotificationSettings
        return notificationSettings?.types.contains([.alert, .badge]) ?? false
    }
    
    var lastAskedForLocationPermission : Date?
    {
        return self.get(forKey: self.lastAskedForLocationPermissionKey)
    }
    
    var userEverGaveLocationPermission: Bool
    {
        return self.getBool(forKey: self.userGaveLocationPermissionKey)
    }
    
    //MARK: Methods
    func lastHealthKitUpdate(for identifier: String) -> Date
    {
        let key = lastHealthKitUpdateKey + identifier
        
        guard let lastUpdate : Date = get(forKey: key)
        else
        {
            return Date()
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
        guard self.installDate == nil else { return }
        
        self.set(date, forKey: self.installDateKey)
    }
    
    func setLastLocation(_ location: CLLocation)
    {
        self.set(location.timestamp, forKey: self.lastLocationDateKey)
        self.set(location.coordinate.latitude, forKey: self.lastLocationLatKey)
        self.set(location.coordinate.longitude, forKey: self.lastLocationLngKey)
        self.set(location.horizontalAccuracy, forKey: self.lastLocationHorizontalAccuracyKey)
    }
    
    func setLastNotificationLocation(_ location: CLLocation)
    {
        self.set(location.timestamp, forKey: self.lastNotificationLocationDateKey)
        self.set(location.coordinate.latitude, forKey: self.lastNotificationLocationLatKey)
        self.set(location.coordinate.longitude, forKey: self.lastNotificationLocationLngKey)
        self.set(location.horizontalAccuracy, forKey: self.lastNotificationLocationHorizontalAccuracyKey)
    }
    
    func setLastAskedForLocationPermission(_ date: Date)
    {
        self.set(date, forKey: self.lastAskedForLocationPermissionKey)
    }
    
    func setUserGaveLocationPermission() {
        self.set(true, forKey: self.userGaveLocationPermissionKey)
    }
    
    // MARK: Helpers
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
