import Foundation
import HealthKit

class HealthKitTemporaryTimeLineGenerator : TemporaryTimelineGenerator
{
    private let trackEventService : TrackEventService
    private let fastMovingSpeedThreshold : Double
    private let minSleepDuration : Double
    private let minGapAllowedDuration : Double
    
    // MARK: - Init
    
    /// Initialiser
    ///
    /// - Parameters:
    ///   - trackEventService: Used to retrive Health TrackEvents
    ///   - fastMovingSpeedThreshold: Used to filter out samples with lower speed than this value (mesured in m/s). Default: 0.3
    ///   - minSleepDuration: Used to filter out sleep with duration lower than this value (mesured in sec). Default: 10.800
    ///   - minGapAllowedDuration: Used to filter out temporaryTimeSlots with duration smaller than this value (mesured in sec). Default: 300
    init(trackEventService: TrackEventService,
         fastMovingSpeedThreshold: Double = 0.3,
         minSleepDuration: Double = 10_800,
         minGapAllowedDuration: Double = 300)
    {
        self.trackEventService = trackEventService
        self.fastMovingSpeedThreshold = fastMovingSpeedThreshold
        self.minSleepDuration = minSleepDuration
        self.minGapAllowedDuration = minGapAllowedDuration
    }
    
    // MARK: - Protocol implementation
    func generateTemporaryTimeline() -> [TemporaryTimeSlot]
    {
        let allHealthSamples = trackEventService
            .getEvents()
            .flatMap(toHealthSample)
            .filter(shortSleepSamples)
            .sorted(by: { $0.startTime < $1.startTime })
        
        let groupedHealthSamples = groupByContinuityAndIdentifier(from: allHealthSamples)
        
        let temporaryTimeSlotsToReturn = groupedHealthSamples
            .flatMap(toTemporaryTimeSlots)
            .flatMap { $0 }
        
        return temporaryTimeSlotsToReturn
    }
    
    // MARK: - Helper
    private func shortSleepSamples(_ healthSample: HealthSample) -> Bool
    {
        guard healthSample.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue else { return true }
        
        return healthSample.endTime.timeIntervalSince(healthSample.startTime) > minSleepDuration
    }
    
    private func toHealthSample(_ trackEvent: TrackEvent) -> HealthSample?
    {
        switch trackEvent {
        case .newHealthSample(let healthSample):
            return healthSample
        default:
            return nil
        }
    }
    
    private func toTemporaryTimeSlots(_ samples: [HealthSample]) -> [TemporaryTimeSlot]?
    {
        guard let first = samples.first else { return nil }
        
        switch first.identifier {
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            return self.makeSlots(fromWalkingAndRunning: samples)
        case HKQuantityTypeIdentifier.distanceCycling.rawValue:
            return self.makeSlots(fromDistanceCycling: samples)
        case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
            return self.makeSlots(fromSleepAnalysis: samples)
        default:
            return nil
        }
    }
    
    private func makeSlots(fromWalkingAndRunning walkingAndRunning: [HealthSample]) -> [TemporaryTimeSlot]?
    {
        guard !walkingAndRunning.isEmpty else { return nil }
        
        var slotsToReturn = [TemporaryTimeSlot]()
        
        var previousSample : HealthSample?
        
        for sample in walkingAndRunning
        {
            let sampleCategory = categoryBasedOnSpeed(sample)
            
            if let previousSample = previousSample, categoryBasedOnSpeed(previousSample) == sampleCategory
            {
                continue
            }
            
            previousSample = sample
            slotsToReturn.append(TemporaryTimeSlot(start: sample.startTime,
                                                   smartGuess: nil,
                                                   category: sampleCategory,
                                                   location: nil))
        }
        
        let lastSample = walkingAndRunning.last!
        
        slotsToReturn.append(TemporaryTimeSlot(start: lastSample.endTime,
                                               smartGuess: nil,
                                               category: .unknown,
                                               location: nil))
        
        return slotsToReturn
    }
    
    private func makeSlots(fromDistanceCycling distanceCycling: [HealthSample]) -> [TemporaryTimeSlot]?
    {
        guard
            let firstSample = distanceCycling.first,
            let lastSample = distanceCycling.last
            else { return nil }
        
        return [ TemporaryTimeSlot(start: firstSample.startTime,
                                   smartGuess: nil,
                                   category: .commute,
                                   location: nil),
                 TemporaryTimeSlot(start: lastSample.endTime,
                                   smartGuess: nil,
                                   category: .unknown,
                                   location: nil) ]
    }
    
    private func makeSlots(fromSleepAnalysis sleepAnalysis: [HealthSample]) -> [TemporaryTimeSlot]?
    {
        guard
            let firstSample = sleepAnalysis.first,
            let lastSample = sleepAnalysis.last
        else { return nil }
        
        return [ TemporaryTimeSlot(start: firstSample.startTime,
                                   smartGuess: nil,
                                   category: .unknown,
                                   location: nil),
                 TemporaryTimeSlot(start: lastSample.endTime,
                                   smartGuess: nil,
                                   category: .unknown,
                                   location: nil) ]
    }
    
    private func categoryBasedOnSpeed(_ sample: HealthSample) -> Category
    {
        return getSpeed(from: sample) > fastMovingSpeedThreshold ?
            .commute :
            .unknown
    }
    
    private func getSpeed(from sample: HealthSample) -> Double
    {
        let duration = getDuration(from: sample)
        
        guard
            let quantity = sample.value as? HKQuantity,
            quantity.is(compatibleWith: .meter()),
            duration > 0
        else { return 0.0 }
        
        let distance = quantity.doubleValue(for: HKUnit.meter())
        return distance / duration
    }
    
    private func getDuration(from sample: HealthSample) -> Double
    {
        return sample.endTime.timeIntervalSince(sample.startTime)
    }
    
    private func groupByContinuityAndIdentifier(from data: [HealthSample]) -> [[HealthSample]]
    {
        var dataToReturn = [[HealthSample]]()
        var currentBatch = [HealthSample]()
        
        func add(_ sample: HealthSample, _ index: Int)
        {
            currentBatch.append(sample)
            if index == data.endIndex - 1
            {
                dataToReturn.append(currentBatch)
                currentBatch.removeAll()
            }
        }
        
        for (index, sample) in data.enumerated()
        {
            if currentBatch.isEmpty
            {
                add(sample, index)
                continue
            }
            
            let previeousSample = currentBatch.last!
            
            if previeousSample.identifier == sample.identifier && previeousSample.endTime.timeIntervalSince(sample.startTime) < TimeInterval(minGapAllowedDuration)
            {
                add(sample, index)
                continue
            }
            
            dataToReturn.append(currentBatch)
            currentBatch.removeAll()
            
            add(sample, index)
        }
        
        return dataToReturn
    }
}
