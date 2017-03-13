import CoreLocation
import CoreData

class LocationModelAdapter : CoreDataModelAdapter<Location>
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
    
    override func getModel(fromManagedObject managedObject: NSManagedObject) -> Location
    {
        let location =  super.getLocation(managedObject,
                                          timeKey: self.locationTimeKey,
                                          latKey: self.locationLatitudeKey,
                                          lngKey: self.locationLongitudeKey)!
        
        return Location(fromLocation: location)
    }
    
    override func setManagedElementProperties(fromModel model: Location, managedObject: NSManagedObject)
    {
        managedObject.setValue(model.timestamp, forKey: self.locationTimeKey)
        managedObject.setValue(model.latitude, forKey: self.locationLatitudeKey)
        managedObject.setValue(model.longitude, forKey: self.locationLongitudeKey)
    }
}
