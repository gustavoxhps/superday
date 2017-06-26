import Foundation
import CoreLocation

class DefaultSmartGuessService : SmartGuessService
{
    typealias KNNInstance = (location: CLLocation, timeStamp: Date, category: Category, smartGuess: SmartGuess?)
    
    //MARK: Private Properties
    private let distanceThreshold = 100.0 //TODO: We have to think about the 100m constant. Might be (significantly?) too low.
    private let timeThreshold : TimeInterval = 5*60*60 //5h
    private let kNeighbors = 3
    private let smartGuessErrorThreshold = 3
    private let smartGuessIdKey = "smartGuessId"
    
    private let timeService : TimeService
    private let loggingService: LoggingService
    private let settingsService: SettingsService
    private let persistencyService : BasePersistencyService<SmartGuess>
    
    //MARK: Initializers
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
    
    //MARK: Public Methods
    
    @discardableResult func add(withCategory category: Category, location: CLLocation) -> SmartGuess?
    {
        let id = getNextSmartGuessId()
        let smartGuess = SmartGuess(withId: id, category: category, location: location, lastUsed: timeService.now)
        
        guard persistencyService.create(smartGuess) else
        {
            loggingService.log(withLogLevel: .warning, message: "Failed to create new SmartGuess")
            return nil
        }
        
        //Bump the identifier
        incrementSmartGuessId()
        loggingService.log(withLogLevel: .info, message: "New SmartGuess with category \"\(smartGuess.category)\" created")
        
        return smartGuess
    }
    
    func markAsUsed(_ smartGuess: SmartGuess, atTime time: Date)
    {
        let id = smartGuess.id
        let predicate = Predicate(parameter: SmartGuessModelAdapter.idKey, equals: id as AnyObject)
        
        guard let persistedSmartGuess = persistencyService.get(withPredicate: predicate).first else
        {
            loggingService.log(withLogLevel: .warning, message: "Tried updating smart guess with invalid id \(id)")
            return
        }
        guard time >= persistedSmartGuess.lastUsed else
        {
            loggingService.log(withLogLevel: .warning, message: "Tried updating smart guess with date before the one already set  \(id)")
            return
        }
        
        let editFunction = { (smartGuess: SmartGuess) -> (SmartGuess) in
            smartGuess.lastUsed = time
            return smartGuess
        }
        
        if !persistencyService.update(withPredicate: predicate, updateFunction: editFunction)
        {
            loggingService.log(withLogLevel: .warning, message: "Error trying to update last-used time of SmartGuess with id \(id)")
        }
        
        smartGuess.lastUsed = time

    }
    
    func strike(withId id: Int)
    {
        let predicate = Predicate(parameter: SmartGuessModelAdapter.idKey, equals: id as AnyObject)
        
        // Invalid Ids should be ignore
        guard let smartGuess = persistencyService.get(withPredicate: predicate).first else
        {
            loggingService.log(withLogLevel: .warning, message: "Tried striking smart guess with invalid id \(id)")
            return
        }
        
        // Purge SmartGuess if needed
        if shouldPurge(smartGuess: smartGuess)
        {
            persistencyService.delete(withPredicate: predicate)
            return
        }
        
        let editFunction = { (smartGuess: SmartGuess) -> (SmartGuess) in
            
            smartGuess.errorCount += 1
            return smartGuess
        }
        
        if !persistencyService.update(withPredicate: predicate, updateFunction: editFunction)
        {
            loggingService.log(withLogLevel: .warning, message: "Error trying to increase errorCount of SmartGuess with id \(id)")
        }
    }
    
    func get(forLocation location: CLLocation) -> SmartGuess?
    {
        let bestMatches = persistencyService.get()
            .filter(isWithinDistanceThreshold(from: location))
            .filter(isWithinTimeThresholdInNearByWeekDay(from: location))
        
        guard bestMatches.count > 0 else { return nil }
        
        let knnInstances = bestMatches.map { (location: $0.location, timeStamp: $0.location.timestamp, category: $0.category, smartGuess: Optional($0)) }
        
        let startTimeForKNN = Date()
        
        let bestKnnMatch = KNN<KNNInstance, Category>
            .prediction(
                for: (location: location, timeStamp: location.timestamp, category: Category.unknown, smartGuess: nil),
                usingK: knnInstances.count >= kNeighbors ? kNeighbors : knnInstances.count,
                with: knnInstances,
                decisionType: .maxScoreSum,
                customDistance: distance,
                labelAction: { $0.category })
        
        loggingService.log(withLogLevel: .debug, message: "KNN executed in \(Date().timeIntervalSince(startTimeForKNN)) with k = \(knnInstances.count >= kNeighbors ? kNeighbors : knnInstances.count) on a dataset of \(knnInstances.count)")
        
        guard let bestMatch = bestKnnMatch?.smartGuess else { return nil }
        
        loggingService.log(withLogLevel: .debug, message: "SmartGuess found for location: \(location.coordinate.latitude),\(location.coordinate.longitude) -> \(bestMatch.category)")
        return bestMatch
    }
    
    func purgeEntries(olderThan maxAge: Date)
    {
        guard let initialDate = settingsService.installDate, maxAge > initialDate else { return }
        
        let predicate = Predicate(parameter: "lastUsed",
                                  rangesFromDate: initialDate as NSDate,
                                  toDate: maxAge as NSDate)
        
        persistencyService.delete(withPredicate: predicate)
    }
    
    //MARK: Private Methods
    
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

        let locationDifference = instance1.location.distance(from: instance2.location) / distanceThreshold
        accumulator += pow(locationDifference, 2)

        let timeDifference = instance1.timeStamp.timeIntervalBasedOnWeekDaySince(instance2.timeStamp) / timeThreshold
        accumulator += pow(timeDifference, 2)
        
        return sqrt(accumulator)
    }
    
    private func getNextSmartGuessId() -> Int
    {
        return UserDefaults.standard.integer(forKey: smartGuessIdKey)
    }
    
    private func incrementSmartGuessId()
    {
        var id = getNextSmartGuessId()
        id += 1
        UserDefaults.standard.set(id, forKey: smartGuessIdKey)
    }
    
    private func shouldPurge(smartGuess: SmartGuess) -> Bool
    {
        return smartGuess.errorCount >= smartGuessErrorThreshold
    }
}
