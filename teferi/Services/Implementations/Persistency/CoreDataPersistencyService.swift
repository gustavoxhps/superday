import CoreData
import UIKit

///Implementation that uses CoreData to persist information on disk.
class CoreDataPersistencyService<T> : BasePersistencyService<T>
{
    //MARK: Fields
    let loggingService : LoggingService
    let modelAdapter : CoreDataModelAdapter<T>
    let managedObjectContext : NSManagedObjectContext
    
    //MARK: Initializers
    init(loggingService: LoggingService, modelAdapter: CoreDataModelAdapter<T>, managedObjectContext: NSManagedObjectContext)
    {
        self.modelAdapter = modelAdapter
        self.loggingService = loggingService
        self.managedObjectContext = managedObjectContext
    }
    
    //MARK: PersistencyService implementation
    override func getLast() -> T?
    {
        var elementToReturn: T? = nil
        
        managedObjectContext.performAndWait
        { [unowned self] in
            let request = NSFetchRequest<NSFetchRequestResult>()
            request.entity = NSEntityDescription.entity(forEntityName: self.entityName, in: self.managedObjectContext)!
            request.fetchLimit = 1
            request.sortDescriptors = self.modelAdapter.sortDescriptors
            
            do
            {
                if let managedElement = try self.managedObjectContext.fetch(request).first as? NSManagedObject
                {
                    elementToReturn = self.mapManagedObjectIntoElement(managedElement)
                }
            }
            catch
            {
                self.loggingService.log(withLogLevel: .warning, message: "No \(self.entityName)s found")
            }
        }
        
        return elementToReturn
    }
    
    override func get(withPredicate predicate: Predicate? = nil) -> [ T ]
    {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        if let nsPredicate = predicate?.convertToNSPredicate()
        {
            fetchRequest.predicate = nsPredicate
        }
        
        var elements = [T]()
        
        managedObjectContext.performAndWait
        { [unowned self] in
            do
            {
                let results = try self.managedObjectContext.fetch(fetchRequest) as! [NSManagedObject]
                
                elements = results.map(self.mapManagedObjectIntoElement)
            }
            catch
            {
                //Returns an empty array if anything goes wrong
                self.loggingService.log(withLogLevel: .warning, message: "No \(self.entityName) found, returning empty array")
            }
        }
        
        return elements
    }
    
    @discardableResult override func create(_ element: T) -> Bool
    {
        var boolToReturn = false
        
        managedObjectContext.performAndWait
        { [unowned self] in
            let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: self.managedObjectContext)!
            let managedObject = NSManagedObject(entity: entity, insertInto: self.managedObjectContext)
            
            //Sets the properties
            self.setManagedElementProperties(element, managedObject)
            
            do
            {
                try self.managedObjectContext.save()
                boolToReturn = true
            }
            catch
            {
                self.loggingService.log(withLogLevel: .warning, message: "Error creating \(self.entityName)")
            }
        }
        
        return boolToReturn
    }
    
    override func update(withPredicate predicate: Predicate, updateFunction: @escaping (T) -> T) -> Bool
    {
        var boolToReturn = false
        
        managedObjectContext.performAndWait
        { [unowned self] in
            let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: self.managedObjectContext)
            
            let request = NSFetchRequest<NSFetchRequestResult>()
            let predicate = predicate.convertToNSPredicate()
            
            request.entity = entity
            request.predicate = predicate
            
            do
            {
                if let managedElement = try self.managedObjectContext.fetch(request).first as AnyObject?
                {
                    let managedObject = managedElement as! NSManagedObject
                    
                    let entity = self.modelAdapter.getModel(fromManagedObject: managedObject)
                    let newEntity = updateFunction(entity)
                    
                    self.setManagedElementProperties(newEntity, managedObject)
                    
                    try self.managedObjectContext.save()
                    
                    boolToReturn = true
                }
            }
            catch
            {
                self.loggingService.log(withLogLevel: .warning, message: "No \(T.self) found when trying to update")
            }
        }
        
        return boolToReturn
    }
    
    @discardableResult override func delete(withPredicate predicate: Predicate? = nil) -> Bool
    {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        
        if let nsPredicate = predicate?.convertToNSPredicate()
        {
            fetchRequest.predicate = nsPredicate
        }
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        var boolToReturn = false
        
        managedObjectContext.performAndWait
        { [unowned self] in
            do
            {
                try self.managedObjectContext.execute(batchDeleteRequest)
                boolToReturn = true
            }
            catch
            {
                //Returns an empty array if anything goes wrong
                self.loggingService.log(withLogLevel: .warning, message: "Failed to delete instances of \(self.entityName)")
            }
        }
        
        return boolToReturn
    }
    
    //MARK: Methods
    private func setManagedElementProperties(_ element: T, _ managedObject: NSManagedObject)
    {
        modelAdapter.setManagedElementProperties(fromModel: element, managedObject: managedObject)
    }
    
    private func mapManagedObjectIntoElement(_ managedObject: NSManagedObject) -> T
    {
        let result = modelAdapter.getModel(fromManagedObject: managedObject)
        return result
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
