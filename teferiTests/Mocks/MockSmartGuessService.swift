@testable import teferi
import CoreLocation

class MockSmartGuessService : SmartGuessService
{
    //MARK: Properties
    private var smartGuessId = 0
    
    var addShouldWork = true
    var smartGuessToReturn : SmartGuess? = nil
    var smartGuessUpdates = [(SmartGuess, Date)]()
    var locationsAskedFor = [CLLocation]()
    var smartGuesses = [SmartGuess]()
    
    func get(forLocation location: CLLocation) -> SmartGuess?
    {
        locationsAskedFor.append(location)
        return smartGuessToReturn
    }
    
    @discardableResult func add(withCategory category: teferi.Category, location: CLLocation) -> SmartGuess?
    {
        let smartGuess = SmartGuess(withId: smartGuessId, category: category, location: location, lastUsed: Date())
        smartGuesses.append(smartGuess)
        
        smartGuessId += 1
        
        return smartGuess
    }
    
    func markAsUsed(_ smartGuess: SmartGuess, atTime time: Date)
    {
        smartGuess.lastUsed = time
        smartGuessUpdates.append(smartGuess, time)
    }
    
    func strike(withId id: Int)
    {
        guard let smartGuessIndex = smartGuesses.index(where: { smartGuess in smartGuess.id == id }) else { return }
        
        let smartGuess = smartGuesses[smartGuessIndex]
        
        if smartGuess.errorCount >= 3
        {
            smartGuesses.remove(at: smartGuessIndex)
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
