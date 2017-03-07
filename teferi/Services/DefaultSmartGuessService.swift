import Foundation
import CoreLocation

class DefaultSmartGuessService : SmartGuessService
{
    typealias KNNInstance = (location: CLLocation, timeStamp: Date, category: Category)
    
    //MARK: Fields
    private let distanceThreshold = 100.0 //TODO: We have to think about the 100m constant. Might be (significantly?) too low.
    private let timeThreshold : TimeInterval = 5*60*60 //5h
    private let kNeighbors = 3
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
            .filter(isWithinTimeThresholdInNearByWeekDay(from: location))
        
        guard bestMatches.count > 0 else { return nil }
        
        let knnInstances = bestMatches.map({ (location: $0.location, timeStamp: $0.location.timestamp, category: $0.category) })
        
        guard let bestKnnMatch = KNN<KNNInstance, Category>
            .prediction(
                for: (location: location, timeStamp: location.timestamp, category: Category.unknown),
                usingK: knnInstances.count >= kNeighbors ? kNeighbors : knnInstances.count,
                with: knnInstances,
                decisionType: .minAvarageDistance,
                customDistance: self.distance,
                labelAction: { $0.category })
        else { return nil }
        
        guard let bestMatch = bestMatches.first(where: { $0.category == bestKnnMatch.category && $0.location == bestKnnMatch.location })
        else { return nil }
        
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
        return { smartGuess in return smartGuess.location.distance(from: location) <= self.distanceThreshold }
    }
    
    private func isWithinTimeThresholdInNearByWeekDay(from location: CLLocation) -> (SmartGuess) -> Bool
    {
        return { smartGuess in
            
            let smartGuessTimestamp = smartGuess.location.timestamp
            let locationTimestamp = location.timestamp
            
            return abs(smartGuessTimestamp.timeIntervalBasedOnWeekDaySince(locationTimestamp)) <= self.timeThreshold
        }
    }
    
    private func distance(instance1: KNNInstance, instance2: KNNInstance) -> Double
    {
        var accumulator = 0.0

        let locationDifference = instance1.location.distance(from: instance2.location) / self.distanceThreshold
        accumulator += pow(locationDifference, 2)

        let timeDifference = instance1.timeStamp.timeIntervalBasedOnWeekDaySince(instance2.timeStamp) / self.timeThreshold
        accumulator += pow(timeDifference, 2)

        return sqrt(accumulator)
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
