import Foundation

///Service that persists data locally
protocol PersistencyService
{
    associatedtype T
    
    //MARK: Methods
    
    ///Returns the last saved instance of type T created.
    func getLast() -> T?
    
    /**
     Get objects givem a predicate.
     
     - Parameter predicate: Predicate used for filtering.
     
     - Returns: The found entities that comply to the provided predicate.
     */
    func get(withPredicate predicate: Predicate?) -> [ T ]
    
    /**
     Persists the provided element.
     
     - Parameter element: The element to be persisted.
     
     - Returns: A Bool indicating whether the operation suceeded or not.
     */
    @discardableResult func create(_ element: T) -> Bool
    
    /**
     Updates the element.
     
     - Parameter predicate: Predicate used for filtering.
     
     - Parameter updateFunction: Function that will apply the changes to the element.
     
     - Returns: A Bool indicating whether the operation suceeded or not.
     */
    @discardableResult func update(withPredicate predicate: Predicate, updateFunction: @escaping (T) -> T) -> Bool
    
    /**
     Updates the element.
     
     - Parameter predicate: Predicate used for filtering.
     
     - Returns: A Bool indicating whether the operation suceeded or not.
     */
    @discardableResult func delete(withPredicate predicate: Predicate?) -> Bool
}

class BasePersistencyService<T> : PersistencyService
{
    
    ///Returns the last saved instance of type T created.
    func getLast() -> T?
    {
        fatalError("Not implemented")
    }
    
    /**
     Get objects givem a predicate.
     
     - Parameter predicate: Predicate used for filtering.
     
     - Returns: The found entities that comply to the provided predicate.
     */
    func get(withPredicate predicate: Predicate? = nil) -> [ T ]
    {
        fatalError("Not implemented")
    }
    
    /**
     Persists the provided element.
     
     - Parameter element: The element to be persisted.
     
     - Returns: A Bool indicating whether the operation suceeded or not.
     */
    @discardableResult func create(_ element: T) -> Bool
    {
        fatalError("Not implemented")
    }
    
    /**
     Updates the provided element.
     
     - Parameter timeSlot: The TimeSlots to be updated.
     
     - Parameter changes: Function that will apply the changes to the element.
     
     - Returns: A Bool indicating whether the operation suceeded or not.
     */
    @discardableResult func update(withPredicate predicate: Predicate, updateFunction: @escaping (T) -> T) -> Bool
    {
        fatalError("Not implemented")
    }
    
    
    /**
     Updates the element.
     
     - Parameter predicate: Predicate used for filtering.
     
     - Returns: A Bool indicating whether the operation suceeded or not.
     */
    @discardableResult func delete(withPredicate predicate: Predicate? = nil) -> Bool
    {
        fatalError("Not implemented")
    }
}
