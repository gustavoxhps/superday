import Foundation
import HealthKit

class DefaultHealthKitTemporaryTimeLineGenerator : TemporaryTimelineGenerator
{
    private let trackEventService : TrackEventService
    private let fastMovingSpeedThreshold : Double
    private let minSleepDuration : Double
    private let minGapAllowedDuration : Double
    
    // MARK: - Init
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
            .filter { (trackEvent) -> Bool in
                switch trackEvent {
                case .newLocation(_):
                    return false
                case .newHealthSample(let healthSample):
                    if healthSample.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue
                    {
                        return healthSample.endTime.timeIntervalSince(healthSample.startTime) > minSleepDuration
                    }
                    return true
                }
            }
            .map { (trackEvent) -> HealthSample! in
                switch trackEvent {
                case .newHealthSample(let healthSample):
                    return healthSample
                default:
                    return nil
                }
            }
            .sorted(by: { $0.startTime < $1.startTime })
        
        let groupedHealthSamples = groupByContinuetyAndIdentifier(from: allHealthSamples)
        
        let temporaryTimeSlotsToReturn = groupedHealthSamples.flatMap(toTemporaryTimeSlots())
        
        return temporaryTimeSlotsToReturn
    }
    
    // MARK: - Helper
    private func toTemporaryTimeSlots() -> ([HealthSample]) -> [TemporaryTimeSlot]
    {
        return { (samples) in
            
            let first = samples.first!
            
            switch first.identifier {
            case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                return self.makeSlots(fromWalkingAndRunning: samples)
            case HKQuantityTypeIdentifier.distanceCycling.rawValue:
                return self.makeSlots(fromDistanceCycling: samples)
            case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
                return self.makeSlots(fromSleepAnalysis: samples)
            default:
                return [TemporaryTimeSlot]()
            }
        }
    }
    
    private func makeSlots(fromWalkingAndRunning walkingAndRunning: [HealthSample]) -> [TemporaryTimeSlot]
    {
        var slotsToReturn = [TemporaryTimeSlot]()
        
        var previousSample : HealthSample?
        
        for sample in walkingAndRunning
        {
            if let previousSample = previousSample, categoryBasedOnSpeed(previousSample) == categoryBasedOnSpeed(sample)
            {
                continue
            }
            
            previousSample = sample
            slotsToReturn.append(TemporaryTimeSlot(start: sample.startTime,
                                                   smartGuess: nil,
                                                   category: categoryBasedOnSpeed(sample),
                                                   location: nil))
        }
        
        let lastSample = walkingAndRunning.last!
        slotsToReturn.append(TemporaryTimeSlot(start: lastSample.endTime,
                                               smartGuess: nil,
                                               category: .unknown,
                                               location: nil))
        
        return slotsToReturn
    }
    
    private func makeSlots(fromDistanceCycling distanceCycling: [HealthSample]) -> [TemporaryTimeSlot]
    {
        let firstSample = distanceCycling.first!
        let lastSample = distanceCycling.last!
        return [ TemporaryTimeSlot(start: firstSample.startTime,
                                   smartGuess: nil,
                                   category: .commute,
                                   location: nil),
                 TemporaryTimeSlot(start: lastSample.endTime,
                                   smartGuess: nil,
                                   category: .unknown,
                                   location: nil) ]
    }
    
    private func makeSlots(fromSleepAnalysis sleepAnalysis: [HealthSample]) -> [TemporaryTimeSlot]
    {
        let firstSample = sleepAnalysis.first!
        let lastSample = sleepAnalysis.last!
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
        let distance = (sample.value as! HKQuantity).doubleValue(for: HKUnit.meter())
        let duration = getDuration(from: sample)
        return distance / duration
    }
    
    private func getDuration(from sample: HealthSample) -> Double
    {
        return sample.endTime.timeIntervalSince(sample.startTime)
    }
    
    private func groupByContinuetyAndIdentifier(from data: [HealthSample]) -> [[HealthSample]]
    {
        var dataToReturn = [[HealthSample]]()
        var currentBatch = [HealthSample]()
        
        for (index, sample) in data.enumerated()
        {
            print(index, data.endIndex - 1)
            if currentBatch.isEmpty
            {
                currentBatch.append(sample)
                if index == data.endIndex - 1
                {
                    dataToReturn.append(currentBatch)
                    currentBatch.removeAll()
                }
                continue
            }
            
            let previeousSample = currentBatch.last!
            
            if previeousSample.identifier == sample.identifier && previeousSample.endTime.timeIntervalSince(sample.startTime) < TimeInterval(minGapAllowedDuration)
            {
                currentBatch.append(sample)
                if index == data.endIndex - 1
                {
                    dataToReturn.append(currentBatch)
                    currentBatch.removeAll()
                }
                continue
            }
            
            dataToReturn.append(currentBatch)
            currentBatch.removeAll()
            
            currentBatch.append(sample)
            if index == data.endIndex - 1
            {
                dataToReturn.append(currentBatch)
                currentBatch.removeAll()
            }
        }
        
        return dataToReturn
    }
}
