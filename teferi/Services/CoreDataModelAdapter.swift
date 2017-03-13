import Foundation
import CoreData
import CoreLocation

class CoreDataModelAdapter<T>
{
    func getModel(fromManagedObject managedObject: NSManagedObject) -> T
    {
        fatalError("Not implemented")
    }
    
    func setManagedElementProperties(fromModel model: T, managedObject: NSManagedObject)
    {
        fatalError("Not implemented")
    }
    
    func getEntityName() -> String
    {
        return entityName
    }
    
    var sortDescriptors : [NSSortDescriptor]!
    
    func getLocation(_ managedObject: NSManagedObject, timeKey: String, latKey: String, lngKey: String) -> CLLocation?
    {
        var location : CLLocation? = nil
        
        let possibleTime = managedObject.value(forKey: timeKey) as? Date
        let possibleLatitude = managedObject.value(forKey: latKey) as? Double
        let possibleLongitude = managedObject.value(forKey: lngKey) as? Double
        
        if let time = possibleTime, let latitude = possibleLatitude, let longitude = possibleLongitude
        {
            let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            location = CLLocation(coordinate: coord, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: time)
        }
        
        return location
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
