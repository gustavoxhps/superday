import HealthKit
import CoreData

class HealthSampleModelAdapter : CoreDataModelAdapter<HealthSample>
{
    //MARK: Fields
    private let valueKey = "value"
    private let endTimeKey = "endTime"
    private let startTimeKey = "startTime"
    private let identifierKey = "identifier"
    
    override init()
    {
        super.init()
        
        sortDescriptors = [ NSSortDescriptor(key: startTimeKey, ascending: false) ]
    }
    
    override func getModel(fromManagedObject managedObject: NSManagedObject) -> HealthSample
    {
        let identifier = managedObject.value(forKey: identifierKey) as! String
        let startTime = managedObject.value(forKey: startTimeKey) as! Date
        let endTime = managedObject.value(forKey: endTimeKey) as! Date
        let value = managedObject.value(forKey: valueKey)
        
        let sample = HealthSample(withIdentifier: identifier,
                                  startTime: startTime,
                                  endTime: endTime,
                                  value: value)
        
        return sample
    }
    
    override func setManagedElementProperties(fromModel model: HealthSample, managedObject: NSManagedObject)
    {
        managedObject.setValue(model.identifier, forKey: identifierKey)
        managedObject.setValue(model.startTime, forKey: startTimeKey)
        managedObject.setValue(model.endTime, forKey: endTimeKey)
        managedObject.setValue(model.value, forKey: valueKey)
    }
}
