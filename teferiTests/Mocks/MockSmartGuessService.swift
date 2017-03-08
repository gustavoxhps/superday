@testable import teferi
import CoreLocation

class MockSmartGuessService : SmartGuessService
{
    //MARK: Properties
    private var id = 0    
    
    var addShouldWork = true
    var smartGuessToReturn : SmartGuess? = nil
    var locationsAskedFor = [CLLocation]()
    var smartGuesses = [SmartGuess]()
    
    func get(forLocation location: CLLocation) -> SmartGuess?
    {
        self.locationsAskedFor.append(location)
        return self.smartGuessToReturn
    }
    
    @discardableResult func add(withCategory category: teferi.Category, location: CLLocation) -> SmartGuess?
    {
        let smartGuess = SmartGuess(withId: id, category: category, location: location, lastUsed: Date())
        self.smartGuesses.append(smartGuess)
        
        return smartGuess
    }
    
    func strike(withId id: Int)
    {
        guard let smartGuessIndex = self.smartGuesses.index(where: { smartGuess in smartGuess.id == id }) else { return }
        
        let smartGuess = self.smartGuesses[smartGuessIndex]
        
        if smartGuess.errorCount >= 3
        {
            self.smartGuesses.remove(at: smartGuessIndex)
        }
        else
        {
            smartGuess.errorCount += 1
        }
    }
    
    func purgeEntries(olderThan maxAge: Date)
    {
        
    }
}
