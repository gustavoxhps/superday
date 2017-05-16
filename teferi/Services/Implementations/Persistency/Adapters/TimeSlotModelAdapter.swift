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
        
        self.sortDescriptors = [ NSSortDescriptor(key: self.startTimeKey, ascending: false) ]
    }
    
    override func getModel(fromManagedObject managedObject: NSManagedObject) -> TimeSlot
    {
        let startTime = managedObject.value(forKey: self.startTimeKey) as! Date
        let endTime = managedObject.value(forKey: self.endTimeKey) as? Date
        let category = Category(rawValue: managedObject.value(forKey: self.categoryKey) as! String)!
        let categoryWasSetByUser = managedObject.value(forKey: self.categoryWasSetByUserKey) as? Bool ?? false
        
        let location = super.getLocation(managedObject,
                                         timeKey: self.locationTimeKey,
                                         latKey: self.locationLatitudeKey,
                                         lngKey: self.locationLongitudeKey)
        
        let timeSlot = TimeSlot(withStartTime: startTime,
                                category: category,
                                categoryWasSetByUser: categoryWasSetByUser,
                                location: location)
        timeSlot.endTime = endTime
        
        return timeSlot
    }
    
    override func setManagedElementProperties(fromModel model: TimeSlot, managedObject: NSManagedObject)
    {
        managedObject.setValue(model.endTime, forKey: self.endTimeKey)
        managedObject.setValue(model.startTime, forKey: self.startTimeKey)
        managedObject.setValue(model.category.rawValue, forKey: self.categoryKey)
        managedObject.setValue(model.categoryWasSetByUser, forKey: self.categoryWasSetByUserKey)
        
        managedObject.setValue(model.location?.timestamp, forKey: self.locationTimeKey)
        managedObject.setValue(model.location?.coordinate.latitude, forKey: self.locationLatitudeKey)
        managedObject.setValue(model.location?.coordinate.longitude, forKey: self.locationLongitudeKey)
    }
}
