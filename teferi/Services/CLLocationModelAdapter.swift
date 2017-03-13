import CoreLocation
import CoreData

class CLLocationModelAdapter : CoreDataModelAdapter<CLLocation>
{
    //MARK: Fields
    private let locationTimeKey = "time"
    private let locationLatitudeKey = "latitude"
    private let locationLongitudeKey = "longitude"
    
    override init()
    {
        super.init()
        
        self.sortDescriptors = [ NSSortDescriptor(key: self.locationTimeKey, ascending: false) ]
    }
    
    override func getModel(fromManagedObject managedObject: NSManagedObject) -> CLLocation
    {
        let location =  super.getLocation(managedObject,
                                          timeKey: self.locationTimeKey,
                                          latKey: self.locationLatitudeKey,
                                          lngKey: self.locationLongitudeKey)
        
        return location!
    }
    
    override func setManagedElementProperties(fromModel model: CLLocation, managedObject: NSManagedObject)
    {
        managedObject.setValue(model.timestamp, forKey: self.locationTimeKey)
        managedObject.setValue(model.coordinate.latitude, forKey: self.locationLatitudeKey)
        managedObject.setValue(model.coordinate.longitude, forKey: self.locationLongitudeKey)
    }
    
    override func getEntityName() -> String
    {
        return "Location"
    }
}
