import CoreLocation
import CoreData

class TimeSlotModelAdapter : CoreDataModelAdapter<TimeSlot>
{
    //MARK: Fields
    private let endTimeKey = "endTime"
    private let categoryKey = "category"
    private let startTimeKey = "startTime"
    private let locationTimeKey = "locationTime"
    private let locationLatitudeKey = "locationLatitude"
    private let locationLongitudeKey = "locationLongitude"
    private let categoryWasSetByUserKey = "categoryWasSetByUser"
    
    override init()
    {
        super.init()
        
        sortDescriptors = [ NSSortDescriptor(key: startTimeKey, ascending: false) ]
    }
    
    override func getModel(fromManagedObject managedObject: NSManagedObject) -> TimeSlot
    {
        let startTime = managedObject.value(forKey: startTimeKey) as! Date
        let endTime = managedObject.value(forKey: endTimeKey) as? Date
        let category = Category(rawValue: managedObject.value(forKey: categoryKey) as! String)!
        let categoryWasSetByUser = managedObject.value(forKey: categoryWasSetByUserKey) as? Bool ?? false
        
        let location = super.getLocation(managedObject,
                                         timeKey: locationTimeKey,
                                         latKey: locationLatitudeKey,
                                         lngKey: locationLongitudeKey)
        
        let timeSlot = TimeSlot(withStartTime: startTime,
                                category: category,
                                categoryWasSetByUser: categoryWasSetByUser,
                                location: location)
        timeSlot.endTime = endTime
        
        return timeSlot
    }
    
    override func setManagedElementProperties(fromModel model: TimeSlot, managedObject: NSManagedObject)
    {
        managedObject.setValue(model.endTime, forKey: endTimeKey)
        managedObject.setValue(model.startTime, forKey: startTimeKey)
        managedObject.setValue(model.category.rawValue, forKey: categoryKey)
        managedObject.setValue(model.categoryWasSetByUser, forKey: categoryWasSetByUserKey)
        
        managedObject.setValue(model.location?.timestamp, forKey: locationTimeKey)
        managedObject.setValue(model.location?.coordinate.latitude, forKey: locationLatitudeKey)
        managedObject.setValue(model.location?.coordinate.longitude, forKey: locationLongitudeKey)
    }
}
