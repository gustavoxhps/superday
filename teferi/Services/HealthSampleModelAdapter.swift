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
        
        self.sortDescriptors = [ NSSortDescriptor(key: self.startTimeKey, ascending: false) ]
    }
    
    override func getModel(fromManagedObject managedObject: NSManagedObject) -> HealthSample
    {
        let identifier = managedObject.value(forKey: self.identifierKey) as! String
        let startTime = managedObject.value(forKey: self.startTimeKey) as! Date
        let endTime = managedObject.value(forKey: self.endTimeKey) as! Date
        let value = managedObject.value(forKey: self.valueKey)
        
        let sample = HealthSample(withIdentifier: identifier,
                                  startTime: startTime,
                                  endTime: endTime,
                                  value: value)
        
        return sample
    }
    
    override func setManagedElementProperties(fromModel model: HealthSample, managedObject: NSManagedObject)
    {
        managedObject.setValue(model.identifier, forKey: self.identifierKey)
        managedObject.setValue(model.startTime, forKey: self.startTimeKey)
        managedObject.setValue(model.endTime, forKey: self.endTimeKey)
        managedObject.setValue(model.value, forKey: self.valueKey)
    }
}
