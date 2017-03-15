import CoreData
import UIKit

///Implementation that uses CoreData to persist information on disk.
class CoreDataPersistencyService<T> : BasePersistencyService<T>
{
    //MARK: Fields
    let loggingService : LoggingService
    let modelAdapter : CoreDataModelAdapter<T>
    
    //MARK: Initializers
    init(loggingService: LoggingService, modelAdapter: CoreDataModelAdapter<T>)
    {
        self.modelAdapter = modelAdapter
        self.loggingService = loggingService
    }
    
    //MARK: PersistencyService implementation
    override func getLast() -> T?
    {
        guard let managedElement = self.getLastManagedElement() else { return nil }
        
        let element = self.mapManagedObjectIntoElement(managedElement)
        return element
    }
    
    override func get(withPredicate predicate: Predicate? = nil) -> [ T ]
    {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        
        if let nsPredicate = predicate?.convertToNSPredicate()
        {
            fetchRequest.predicate = nsPredicate
        }
        
        do
        {
            let results = try self.getManagedObjectContext().fetch(fetchRequest) as! [NSManagedObject]
            
            let elements = results.map(self.mapManagedObjectIntoElement)
            return elements
        }
        catch
        {
            //Returns an empty array if anything goes wrong
            self.loggingService.log(withLogLevel: .warning, message: "No \(self.entityName) found, returning empty array")
            return []
        }
    }
    
    @discardableResult override func create(_ element: T) -> Bool
    {
        //Gets the managed object from CoreData's context
        let managedContext = self.getManagedObjectContext()
        let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: managedContext)!
        let managedObject = NSManagedObject(entity: entity, insertInto: managedContext)
        
        //Sets the properties
        self.setManagedElementProperties(element, managedObject)
        
        do
        {
            try managedContext.save()
            return true
        }
        catch
        {
            self.loggingService.log(withLogLevel: .error, message: "Error creating \(self.entityName)")
            return false
        }
    }
    
    override func update(withPredicate predicate: Predicate, updateFunction: (T) -> T) -> Bool
    {
        let managedContext = self.getManagedObjectContext()
        let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: managedContext)
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        let predicate = predicate.convertToNSPredicate()
        
        request.entity = entity
        request.predicate = predicate
        
        do
        {
            guard let managedElement = try managedContext.fetch(request).first as AnyObject? else { return false }
            let managedObject = managedElement as! NSManagedObject
            
            let entity = self.modelAdapter.getModel(fromManagedObject: managedObject)
            let newEntity = updateFunction(entity)
            
            self.setManagedElementProperties(newEntity, managedObject)
            
            try managedContext.save()
            
            return true
        }
        catch
        {
            self.loggingService.log(withLogLevel: .warning, message: "No \(T.self) found when trying to update")
            return false
        }
    }
    
    @discardableResult override func delete(withPredicate predicate: Predicate) -> Bool
    {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        fetchRequest.predicate = predicate.convertToNSPredicate()
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do
        {
            try self.getManagedObjectContext().execute(batchDeleteRequest)
            return true
        }
        catch
        {
            //Returns an empty array if anything goes wrong
            self.loggingService.log(withLogLevel: .warning, message: "Failed to delete instances of \(self.entityName)")
            return false
        }
        
    }
    
    //MARK: Methods
    private func getManagedObjectContext() -> NSManagedObjectContext
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.managedObjectContext
    }
    
    private func setManagedElementProperties(_ element: T, _ managedObject: NSManagedObject)
    {
        self.modelAdapter.setManagedElementProperties(fromModel: element, managedObject: managedObject)
    }
    
    private func mapManagedObjectIntoElement(_ managedObject: NSManagedObject) -> T
    {
        let result = self.modelAdapter.getModel(fromManagedObject: managedObject)
        return result
    }
    
    private func getLastManagedElement() -> NSManagedObject?
    {
        let managedContext = self.getManagedObjectContext()
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: self.entityName, in: managedContext)!
        request.fetchLimit = 1
        request.sortDescriptors = self.modelAdapter.sortDescriptors
        
        do
        {
            guard let managedElement = try managedContext.fetch(request).first else { return nil }
            return managedElement as? NSManagedObject
        }
        catch
        {
            self.loggingService.log(withLogLevel: .error, message: "No \(self.entityName)s found")
            return nil
        }
    }
    
    private lazy var entityName : String =
    {
        let fullName = String(describing: T.self)
        let range = fullName.range(of: ".", options: .backwards)
        if let range = range
        {
            return fullName.substring(from: range.upperBound)
        }
        else
        {
            return fullName
        }
    }()
}
