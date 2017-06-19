import CoreData
import CoreLocation

class SmartGuessModelAdapter : CoreDataModelAdapter<SmartGuess>
{
    static let idKey = "id"
    
    //MARK: Private Properties
    private let lastUsedKey = "lastUsed"
    private let categoryKey = "category"
    private let errorCountKey = "errorCount"
    private let locationTimeKey = "locationTime"
    private let locationLatitudeKey = "locationLatitude"
    private let locationLongitudeKey = "locationLongitude"
    
    //MARK: Initializers
    override init()
    {
        super.init()
        
        sortDescriptors = [ NSSortDescriptor(key: locationTimeKey, ascending: false) ]
    }
    
    //MARK: Public Methods
    override func getModel(fromManagedObject managedObject: NSManagedObject) -> SmartGuess
    {
        let id = managedObject.value(forKey: SmartGuessModelAdapter.idKey) as! Int
        let lastUsed = managedObject.value(forKey: lastUsedKey) as! Date
        let errorCount = managedObject.value(forKey: errorCountKey) as! Int
        let category = Category(rawValue: managedObject.value(forKey: categoryKey) as! String)!
        
        let location = super.getLocation(managedObject,
                                         timeKey: locationTimeKey,
                                         latKey: locationLatitudeKey,
                                         lngKey: locationLongitudeKey)!
        
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
        managedObject.setValue(model.category.rawValue, forKey: categoryKey)
        managedObject.setValue(model.lastUsed, forKey: lastUsedKey)
        managedObject.setValue(model.errorCount, forKey: errorCountKey)
        
        managedObject.setValue(model.location.timestamp, forKey: locationTimeKey)
        managedObject.setValue(model.location.coordinate.latitude, forKey: locationLatitudeKey)
        managedObject.setValue(model.location.coordinate.longitude, forKey: locationLongitudeKey)
    }
}
