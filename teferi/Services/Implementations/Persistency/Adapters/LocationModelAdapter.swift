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
        
        sortDescriptors = [ NSSortDescriptor(key: timestampKey, ascending: false) ]
    }
    
    override func getModel(fromManagedObject managedObject: NSManagedObject) -> Location
    {
        let speed = managedObject.value(forKey: speedKey) as! Double
        let course = managedObject.value(forKey: courseKey) as! Double
        let timestamp = managedObject.value(forKey: timestampKey) as! Date
        let altitude = managedObject.value(forKey: altitudeKey) as! Double
        let latitude = managedObject.value(forKey: latitudeKey) as! Double
        let longitude = managedObject.value(forKey: longitudeKey) as! Double
        let verticalAccuracy = managedObject.value(forKey: verticalAccuracyKey) as! Double
        let horizontalAccuracy = managedObject.value(forKey: horizontalAccuracyKey) as! Double
        
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
        managedObject.setValue(model.speed, forKey: speedKey)
        managedObject.setValue(model.course, forKey: courseKey)
        managedObject.setValue(model.altitude, forKey: altitudeKey)
        managedObject.setValue(model.latitude, forKey: latitudeKey)
        managedObject.setValue(model.longitude, forKey: longitudeKey)
        managedObject.setValue(model.timestamp, forKey: timestampKey)
        managedObject.setValue(model.verticalAccuracy, forKey: verticalAccuracyKey)
        managedObject.setValue(model.horizontalAccuracy, forKey: horizontalAccuracyKey)
    }
}
