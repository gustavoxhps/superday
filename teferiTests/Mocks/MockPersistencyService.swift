@testable import teferi
import Foundation

class MockPersistencyService<T> : BasePersistencyService<T>
{
    var elements = [T]()
    var elementsToReturnOnGet : [T]? = nil
    
    override func getLast() -> T?
    {
        return elements.last
    }

    override func get(withPredicate predicate: Predicate? = nil) -> [ T ]
    {
        return elementsToReturnOnGet ?? elements
    }
    
    @discardableResult override func create(_ element: T) -> Bool
    {
        elements.append(element)
        return true
    }
    
    @discardableResult override func update(withPredicate predicate: Predicate, updateFunction: @escaping (T) -> T) -> T?
    {
        return nil
    }
    
    @discardableResult override func delete(withPredicate predicate: Predicate?) -> Bool
    {
        return true
    }
}
