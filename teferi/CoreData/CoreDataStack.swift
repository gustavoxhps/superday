import Foundation
import CoreData

class CoreDataStack
{
    private let loggingService : LoggingService
    
    private(set) lazy var managedObjectContext : NSManagedObjectContext =
        {
            // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
            var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
            return managedObjectContext
    }()
    
    // MARK: Core Data stack
    private lazy var applicationDocumentsDirectory : URL =
    {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.toggl.teferi" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count - 1]
    }()
    
    private lazy var managedObjectModel : NSManagedObjectModel =
    {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        guard let modelURL = Bundle.main.url(forResource: "teferi", withExtension: "momd") else {
            self.loggingService.log(withLogLevel: .error, message: "Unable to Find Data Model")
            fatalError("Unable to Find Data Model")
        }
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            self.loggingService.log(withLogLevel: .error, message: "Unable to Load Data Model")
            fatalError("Unable to Load Data Model")
        }
        
        return managedObjectModel
    }()
    
    private lazy var persistentStoreCoordinator : NSPersistentStoreCoordinator =
    {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        do
        {
            let options = [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true
            ]
            
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        }
        catch
        {
            let nsError = error as NSError
            self.loggingService.log(withLogLevel: .error, message: "\(nsError.userInfo)")
            fatalError("Unable to Load Persistent Store")
        }
        
        return coordinator
    }()
    
    init(loggingService: LoggingService)
    {
        self.loggingService = loggingService
    }
    
    func saveContext()
    {
        if managedObjectContext.hasChanges
        {
            do
            {
                try managedObjectContext.save()
            }
            catch
            {
                // Replace this implementation with code to handle the error appropriately.
                let nsError = error as NSError
                self.loggingService.log(withLogLevel: .error, message: "\(nsError.userInfo)")
            }
        }
    }
}
