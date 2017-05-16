import CoreData
import CoreLocation

class SmartGuessModelAdapter : CoreDataModelAdapter<SmartGuess>
{
    //MARK: Fields
    static let idKey = "id"
    
    private let lastUsedKey = "lastUsed"
    private let categoryKey = "category"
    private let errorCountKey = "errorCount"
    private let locationTimeKey = "locationTime"
    private let locationLatitudeKey = "locationLatitude"
    private let locationLongitudeKey = "locationLongitude"
    
    override init()
    {
        super.init()
        
        self.sortDescriptors = [ NSSortDescriptor(key: self.locationTimeKey, ascending: false) ]
    }
    
    override func getModel(fromManagedObject managedObject: NSManagedObject) -> SmartGuess
    {
        let id = managedObject.value(forKey: SmartGuessModelAdapter.idKey) as! Int
        let lastUsed = managedObject.value(forKey: self.lastUsedKey) as! Date
        let errorCount = managedObject.value(forKey: self.errorCountKey) as! Int
        let category = Category(rawValue: managedObject.value(forKey: self.categoryKey) as! String)!
        
        let location = super.getLocation(managedObject,
                                         timeKey: self.locationTimeKey,
                                         latKey: self.locationLatitudeKey,
                                         lngKey: self.locationLongitudeKey)!
        
        let smartGuess = SmartGuess(withId: id,
                                    category: category,
                                    location: location,
                                    lastUsed: lastUsed,
                                    errorCount: errorCount)
        
        smartGuess.lastUsed = lastUsed
        
        return smartGuess
    }
    
    override func setManagedElementProperties(fromModel model: SmartGuess, managedObject: NSManagedObject)
    {
        managedObject.setValue(model.id, forKey: SmartGuessModelAdapter.idKey)
        managedObject.setValue(model.category.rawValue, forKey: self.categoryKey)
        managedObject.setValue(model.lastUsed, forKey: self.lastUsedKey)
        managedObject.setValue(model.errorCount, forKey: self.errorCountKey)
        
        managedObject.setValue(model.location.timestamp, forKey: self.locationTimeKey)
        managedObject.setValue(model.location.coordinate.latitude, forKey: self.locationLatitudeKey)
        managedObject.setValue(model.location.coordinate.longitude, forKey: self.locationLongitudeKey)
    }
}
