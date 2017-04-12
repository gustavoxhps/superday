import Foundation
import HealthKit
import RxSwift

class DefaultHealthKitService : HealthKitService, EventSource
{
    private let commuteSpeed = 0.3
    private let loggingService : LoggingService
    private let settingsService : SettingsService
    private let sampleSubject = PublishSubject<HealthSample>()
    
    private let healthStore: HKHealthStore? =
    {
        return HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    }()
    
    private let typeIdentifiers : [String] = [HKCategoryTypeIdentifier.sleepAnalysis.rawValue,
                                              HKQuantityTypeIdentifier.distanceCycling.rawValue,
                                              HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue]
    
    private lazy var sampleTypesToRead : [String: HKSampleType] =
    {
        return self.typeIdentifiers.toDictionary(self.sampleType)
    }()
    
    private let dateTimeFormatter = DateFormatter()
    
    // MARK: - Init
    init(settingsService: SettingsService, loggingService: LoggingService)
    {
        self.settingsService = settingsService
        self.loggingService = loggingService
        
        self.loggingService.log(withLogLevel: .verbose, message: "DefaultHealthKitService Initialized")
        
        self.dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    private(set) lazy var eventObservable : Observable<TrackEvent> =
    {
        return self.sampleSubject
                   .asObservable()
                   .map(HealthSample.asTrackEvent)
    }()
    
    // MARK: - New Sample Handler
    private func handle(samples: [HKSample]?)
    {
        guard let samples = samples, !samples.isEmpty else { return }
        
        samples.flatMap(HealthSample.init(fromHKSample:)).forEach(self.sampleSubject.onNext)
        
        let identifier = samples.first!.sampleType.identifier
        
        switch identifier {
        case HKQuantityTypeIdentifier.distanceCycling.rawValue:
            handleDistanceCycling(samples: samples as! [HKQuantitySample])
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            handleDistanceWalkingRunning(samples: samples as! [HKQuantitySample])
        case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
            handleSleepAnalysis(samples: samples as! [HKCategorySample])
        default:
            break
        }
        
        self.settingsService.setLastHealthKitUpdate(for: identifier, date: samples.last!.endDate)
    }
    
    // MARK: - Handling logic per type
    private func handleDistanceCycling(samples: [HKQuantitySample])
    {
        guard let identifier = samples.first?.sampleType.identifier else { return }
        
        self.loggingService.log(withLogLevel: .info, message: "\(samples.count) new healthKit data for identifier \(identifier)")
        
        samples.forEach({ (sample) in
            let quantity = sample.quantity.doubleValue(for: HKUnit.meter())
            self.loggingService.log(withLogLevel: .info, message: "⌞ \(quantity)m start \(self.dateTimeFormatter.string(from: sample.startDate)) end \(self.dateTimeFormatter.string(from: sample.endDate)) metadata: \(String(describing: sample.metadata))")
        })
    }
    
    private func handleDistanceWalkingRunning(samples: [HKQuantitySample])
    {
        guard let identifier = samples.first?.sampleType.identifier else { return }
        
        self.loggingService.log(withLogLevel: .info, message: "\(samples.count) new healthKit data for identifier \(identifier)")
        
        samples.forEach({ (sample) in
            let quantity = sample.quantity.doubleValue(for: HKUnit.meter())
            self.loggingService.log(withLogLevel: .info, message: "⌞ \(quantity)m start \(self.dateTimeFormatter.string(from: sample.startDate)) end \(self.dateTimeFormatter.string(from: sample.endDate)) metadata: \(String(describing: sample.metadata))")
        })
    }
    
    private func handleSleepAnalysis(samples: [HKCategorySample])
    {
        guard let identifier = samples.first?.sampleType.identifier else { return }
        
        self.loggingService.log(withLogLevel: .info, message: "\(samples.count) new healthKit data for identifier \(identifier)")
        
        samples.forEach({ (sample) in
            var sleepAnalysisType = ""
            if let categoryValueSleepAnalysis = HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                if #available(iOS 10.0, *) {
                    switch categoryValueSleepAnalysis {
                    case .asleep:
                        sleepAnalysisType = "asleep"
                    case .inBed:
                        sleepAnalysisType = "inBed"
                    case .awake:
                        sleepAnalysisType = "awake"
                    }
                } else {
                    switch categoryValueSleepAnalysis {
                    case .asleep:
                        sleepAnalysisType = "asleep"
                    case .inBed:
                        sleepAnalysisType = "inBed"
                    default: break
                    }
                }
            }
            
            self.loggingService.log(withLogLevel: .info, message: "⌞ \(sleepAnalysisType) start \(self.dateTimeFormatter.string(from: sample.startDate)) end \(self.dateTimeFormatter.string(from: sample.endDate)) metadata: \(String(describing: sample.metadata))")
        })
    }
    
    // MARK: - Helper methods
    private func sampleType(forIdentifier identifier: String) -> HKSampleType
    {
        if let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: identifier))
        {
            return quantityType
        }
        
        if let categoryType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: identifier))
        {
            return categoryType
        }
        
        fatalError("\(identifier) identifier is unknown")
    }
    
    private func backgroundQuery(forSample sample: HKSampleType) -> HKQuery
    {
        return HKObserverQuery(sampleType: sampleTypesToRead[sample.identifier]!,
                               predicate: self.predicate(from: self.settingsService.lastHealthKitUpdate(for: sample.identifier)),
                               updateHandler: self.newBackgroundUpdateHandler)
    }
    
    private func newBackgroundUpdateHandler(with query: HKObserverQuery, completionHandler: @escaping HKObserverQueryCompletionHandler, error: Error?)
    {
        guard
            let objectType = query.objectType,
            typeIdentifiers.contains(objectType.identifier)
            else
        {
            completionHandler()
            return
        }
        
        let sampleQuery = HKSampleQuery(sampleType: sampleTypesToRead[objectType.identifier]!,
                                        predicate: predicate(from: self.settingsService.lastHealthKitUpdate(for: objectType.identifier)),
                                        limit: HKObjectQueryNoLimit,
                                        sortDescriptors: [NSSortDescriptor(key: "startDate", ascending: true)])
        { (query, results, error) in
            self.handle(samples: results)
            completionHandler()
        }
        
        healthStore?.execute(sampleQuery)
    }
    
    private func predicate(from date: Date) -> NSPredicate
    {
        return NSPredicate(format: "startDate >= %@", argumentArray: [date])
    }
    
    // MARK: - Protocol implementation
    func startHealthKitTracking()
    {
        requestAuthorization { (success) in
            guard success else { return }
            
            self.sampleTypesToRead.values.forEach({ (sample) in
                
                self.healthStore?.execute(self.backgroundQuery(forSample: sample))
                
                self.healthStore?.enableBackgroundDelivery(for: sample, frequency: .immediate, withCompletion: { (success, error) in
                    if success
                    {
                        self.loggingService.log(withLogLevel: .info, message: "Success enable of background delivery in health kit for quantityType: \(sample.identifier)")
                    }
                    
                    if let error = error
                    {
                        self.loggingService.log(withLogLevel: .error, message: "Error trying to enable background delivery in health kit: \(error.localizedDescription)")
                    }
                })
            })
        }
    }
    
    func stopHealthKitTracking()
    {
        requestAuthorization { (success) in
            guard success else { return }
            
            self.healthStore?.disableAllBackgroundDelivery(completion: { (success, error) in
                if success
                {
                    self.loggingService.log(withLogLevel: .info, message: "Success disable of background delivery in health kit")
                }
                
                if let error = error
                {
                    self.loggingService.log(withLogLevel: .error, message: "Error trying to disable background delivery in health kit: \(error.localizedDescription)")
                }
                
                self.sampleTypesToRead.values.forEach({ (sample) in
                    self.healthStore?.stop(self.backgroundQuery(forSample: sample))
                })
            })
        }
    }
    
    func requestAuthorization(completion: ((Bool)->())?)
    {
        healthStore?.requestAuthorization(toShare: nil, read: Set(sampleTypesToRead.values), completion: { (success, error) in
            if let error = error
            {
                self.loggingService.log(withLogLevel: .error, message: "Error trying to authorize health kit: \(error.localizedDescription)")
            }
            completion?(success)
        })
    }
}
