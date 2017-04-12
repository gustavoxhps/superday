@testable import teferi
import Foundation

class MockSmartGuessPersistencyService : BasePersistencyService<SmartGuess>
{
    var smartGuessToGet : SmartGuess!
    var smartGuesses = [SmartGuess]()
    
    override func getLast() -> T?
    {
        return smartGuesses.last
    }
    
    override func get(withPredicate predicate: Predicate? = nil) -> [ T ]
    {
        return smartGuesses
    }
    
    @discardableResult override func create(_ element: T) -> Bool
    {
        smartGuesses.append(element)
        return true
    }
    
    @discardableResult override func update(withPredicate predicate: Predicate, updateFunction: @escaping (T) -> T) -> Bool
    {
        return true
    }
    
    @discardableResult override func delete(withPredicate predicate: Predicate?) -> Bool
    {
        smartGuesses.remove(at: 0)
        return true
    }

}
