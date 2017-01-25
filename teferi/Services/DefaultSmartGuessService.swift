import Foundation
import CoreLocation

class DefaultSmartGuessService : SmartGuessService
{
    typealias WeightedGuess = (smartGuess: SmartGuess, weight: Double)
    
    //MARK: Fields
    private let distanceThreshold = 100.0
    private let smartGuessErrorThreshold = 3
    private let smartGuessIdKey = "smartGuessId"
    
    private let timeService : TimeService
    private let loggingService: LoggingService
    private let settingsService: SettingsService
    private let persistencyService : BasePersistencyService<SmartGuess>
    
    init(timeService: TimeService,
         loggingService: LoggingService,
         settingsService: SettingsService,
         persistencyService: BasePersistencyService<SmartGuess>)
    {
        self.timeService = timeService
        self.loggingService = loggingService
        self.settingsService = settingsService
        self.persistencyService = persistencyService
    }
    
    @discardableResult func add(withCategory category: Category, location: CLLocation) -> SmartGuess?
    {
        let id = self.getNextSmartGuessId()
        let smartGuess = SmartGuess(withId: id, category: category, location: location, lastUsed: self.timeService.now)
        
        guard self.persistencyService.create(smartGuess) else
        {
            self.loggingService.log(withLogLevel: .error, message: "Failed to create new SmartGuess")
            return nil
        }
        
        //Bump the identifier
        self.incrementSmartGuessId()
        self.loggingService.log(withLogLevel: .info, message: "New SmartGuess with category \"\(smartGuess.category)\" created")
        
        return smartGuess
    }
    
    func strike(withId id: Int)
    {
        let predicate = Predicate(parameter: SmartGuessModelAdapter.idKey, equals: id as AnyObject)
        
        // Invalid Ids should be ignore
        guard let smartGuess = self.persistencyService.get(withPredicate: predicate).first else
        {
            self.loggingService.log(withLogLevel: .warning, message: "Tried striking smart guess with invalid id \(id)")
            return
        }
        
        // Purge SmartGuess if needed
        if self.shouldPurge(smartGuess: smartGuess)
        {
            self.persistencyService.delete(withPredicate: predicate)
            return
        }
        
        let editFunction = { (smartGuess: SmartGuess) -> (SmartGuess) in
            
            smartGuess.errorCount += 1
            return smartGuess
        }
        
        if !self.persistencyService.update(withPredicate: predicate, updateFunction: editFunction)
        {
            self.loggingService.log(withLogLevel: .warning, message: "Error trying to increase errorCount of SmartGuess with id \(id)")
        }
    }
    
    func get(forLocation location: CLLocation) -> SmartGuess?
    {
        let bestMatches = self.persistencyService.get()
            .filter(isWithinDistanceThreshold(from: location))
            .filter(isSameWeekDay(from: location))
            .sorted(by: distance(from: location))
        
        guard bestMatches.count > 0 else { return nil }
        
        let minimumDistance = bestMatches.first!.location.distance(from: location)
        
        guard let bestMatch =
            bestMatches
                .groupBy(category)
                .map(toWeightedDistance(from: location, withMinimumDistance: minimumDistance))
                .sorted(by: weight)
                .first?.smartGuess else { return nil }
        
        //Every time a dictionary entry gets used in a guess, it gets refreshed.
        //Entries not refresh in N days get purged
        let lastUsedDate = self.timeService.now
        
        let predicate = Predicate(parameter: SmartGuessModelAdapter.idKey, equals: bestMatch.id as AnyObject)
        self.persistencyService.update(withPredicate: predicate, updateFunction: { smartGuess in
            smartGuess.lastUsed = lastUsedDate
            return smartGuess
        })
        
        bestMatch.lastUsed = lastUsedDate
        
        return bestMatch
    }
    
    func purgeEntries(olderThan maxAge: Date)
    {
        guard let initialDate = self.settingsService.installDate, maxAge > initialDate else { return }
        
        let predicate = Predicate(parameter: "lastUsed",
                                  rangesFromDate: initialDate as NSDate,
                                  toDate: maxAge as NSDate)
        
        self.persistencyService.delete(withPredicate: predicate)
    }
    
    private func isWithinDistanceThreshold(from location: CLLocation) -> (SmartGuess) -> Bool
    {
        //TODO: We have to think about the 100m constant. Might be (significantly?) too low.
        return { smartGuess in return smartGuess.location.distance(from: location) <= self.distanceThreshold }
    }
    
    private func isSameWeekDay(from location: CLLocation) -> (SmartGuess) -> Bool
    {
        return { smartGuess in return Calendar.current.isDate(smartGuess.location.timestamp, inSameDayAs: location.timestamp)  }
    }
    
    private func distance(from location: CLLocation) -> (SmartGuess, SmartGuess) -> Bool
    {
        return { (smartGuess1, smartGuess2) in smartGuess1.location.distance(from: location) > smartGuess2.location.distance(from: location) }
    }
    
    private func category(_ smartGuess: SmartGuess) -> Category
    {
        return smartGuess.category
    }
    
    private func toWeightedDistance(from location: CLLocation, withMinimumDistance minimumDistance: Double) ->
        ([SmartGuess]) -> WeightedGuess
    {
        return { smartGuesses in
            
            let weight = smartGuesses.reduce(0.0, self.weightedSumOfDistances(from: location, withMinimumDistance: minimumDistance))
        
            return (smartGuesses.first!, weight: weight)
        }
    }
    
    private func weightedSumOfDistances(from location: CLLocation, withMinimumDistance minimumDistance: Double) ->
        (_ accumulator: Double, _ smartGuess: SmartGuess) -> Double
    {
        let divideConstant = self.distanceThreshold - minimumDistance
        
        return { (accumulator, smartGuess) in
            
            let distance = smartGuess.location.distance(from: location)
            let weight = (self.distanceThreshold - distance) / divideConstant
            return accumulator + pow(weight, 2)
        }
    }
    
    private func weight(_ weightedGuess1: WeightedGuess, _ weightedGuess2: WeightedGuess) -> Bool
    {
        return weightedGuess1.weight > weightedGuess2.weight
    }
    
    private func getNextSmartGuessId() -> Int
    {
        return UserDefaults.standard.integer(forKey: self.smartGuessIdKey)
    }
    
    private func incrementSmartGuessId()
    {
        var id = self.getNextSmartGuessId()
        id += 1
        UserDefaults.standard.set(id, forKey: self.smartGuessIdKey)
    }
    
    private func shouldPurge(smartGuess: SmartGuess) -> Bool
    {
        return smartGuess.errorCount >= smartGuessErrorThreshold
    }
}
