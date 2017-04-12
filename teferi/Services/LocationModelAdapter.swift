import CoreLocation
import CoreData

class LocationModelAdapter : CoreDataModelAdapter<Location>
{
    //MARK: Fields
    private let speedKey = "speed"
    private let courseKey = "course"
    private let altitudeKey = "altitude"
    private let latitudeKey = "latitude"
    private let longitudeKey = "longitude"
    private let timestampKey = "timestamp"
    private let verticalAccuracyKey = "verticalAccuracy"
    private let horizontalAccuracyKey = "horizontalAccuracy"
    
    override init()
    {
        super.init()
        
        self.sortDescriptors = [ NSSortDescriptor(key: self.timestampKey, ascending: false) ]
    }
    
    override func getModel(fromManagedObject managedObject: NSManagedObject) -> Location
    {
        let speed = managedObject.value(forKey: self.speedKey) as! Double
        let course = managedObject.value(forKey: self.courseKey) as! Double
        let timestamp = managedObject.value(forKey: self.timestampKey) as! Date
        let altitude = managedObject.value(forKey: self.altitudeKey) as! Double
        let latitude = managedObject.value(forKey: self.latitudeKey) as! Double
        let longitude = managedObject.value(forKey: self.longitudeKey) as! Double
        let verticalAccuracy = managedObject.value(forKey: self.verticalAccuracyKey) as! Double
        let horizontalAccuracy = managedObject.value(forKey: self.horizontalAccuracyKey) as! Double
        
        let location =  Location(timestamp: timestamp,
                                 latitude: latitude,
                                 longitude: longitude,
                                 speed: speed,
                                 course: course,
                                 altitude: altitude,
                                 verticalAccuracy: verticalAccuracy,
                                 horizontalAccuracy: horizontalAccuracy)
        
        return location
    }
    
    override func setManagedElementProperties(fromModel model: Location, managedObject: NSManagedObject)
    {
        managedObject.setValue(model.speed, forKey: self.speedKey)
        managedObject.setValue(model.course, forKey: self.courseKey)
        managedObject.setValue(model.altitude, forKey: self.altitudeKey)
        managedObject.setValue(model.latitude, forKey: self.latitudeKey)
        managedObject.setValue(model.longitude, forKey: self.longitudeKey)
        managedObject.setValue(model.timestamp, forKey: self.timestampKey)
        managedObject.setValue(model.verticalAccuracy, forKey: self.verticalAccuracyKey)
        managedObject.setValue(model.horizontalAccuracy, forKey: self.horizontalAccuracyKey)
    }
}
