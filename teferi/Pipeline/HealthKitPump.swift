import Foundation
import HealthKit

class HealthKitPump : Pump
{
    typealias Seconds = Double
    typealias MetersPerSecond = Double
    
    private let trackEventService : TrackEventService
    private let fastMovingSpeedThreshold : MetersPerSecond
    private let minGapAllowedDuration : Seconds
    private let minimumAllowedCommuteDuration : Seconds
    private let loggingService : LoggingService
    
    // MARK: - Init
    
    /// Initialiser
    ///
    /// - Parameters:
    ///   - trackEventService: Used to retrive Health TrackEvents
    ///   - fastMovingSpeedThreshold: Used to filter out samples with lower speed than this value (mesured in m/s). Default: 0.3
    ///   - minGapAllowedDuration: Used to filter out temporaryTimeSlots with duration smaller than this value (mesured in sec). Default: 300
    init(trackEventService: TrackEventService,
         fastMovingSpeedThreshold: Double = 0.3,
         minGapAllowedDuration: Seconds = 15 * 60,
         minimumAllowedCommuteDuration: Seconds = 5 * 60,
         loggingService: LoggingService)
    {
        self.trackEventService = trackEventService
        self.fastMovingSpeedThreshold = fastMovingSpeedThreshold
        self.minGapAllowedDuration = minGapAllowedDuration
        self.minimumAllowedCommuteDuration = minimumAllowedCommuteDuration
        self.loggingService = loggingService
    }
    
    // MARK: - Protocol implementation
    func run() -> [TemporaryTimeSlot]
    {
        let groupedHealthSamples = trackEventService
            .getEventData(ofType: HealthSample.self)
            .distinct()
            .sorted(by: { $0.startTime < $1.startTime })
            .filter(isSampleInBed)
            .splitBy(sameIdAndContinuous)
        
        let temporaryTimeSlots = groupedHealthSamples
            .flatMap(toTemporaryTimeSlots)
            .flatMap { $0 }
                
        let temporaryTimeSlotsWithRemovedSmallSlots = removeSmallUnknownTimeSlots(from: temporaryTimeSlots)
        
        var temporaryTimeSlotsToReturn = temporaryTimeSlotsWithRemovedSmallSlots
            .splitBy({ $0.category == $1.category && $0.category == .commute })
            .flatMap { $0.first }
        
        temporaryTimeSlotsToReturn = removeSmallCommutesTimeSlots(from: temporaryTimeSlotsToReturn)

        loggingService.log(withLogLevel: .info, message: "HealthKit pump temporary timeline:")
        temporaryTimeSlotsToReturn.forEach { (slot) in
            self.loggingService.log(withLogLevel: .debug, message: "HKTempSlot start: \(slot.start) category: \(slot.category.rawValue)")
        }
        
        return temporaryTimeSlotsToReturn.withEndSetToStartOfNext()
    }
    
    // MARK: - Helper
    private func isSampleInBed(sample: HealthSample) -> Bool
    {
        guard sample.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue else { return true }
        guard let value = (sample.value as? HKCategoryValue)?.rawValue else { return true }
        
        return value == HKCategoryValueSleepAnalysis.inBed.rawValue
    }
    
    private func sameIdAndContinuous(previousSample: HealthSample, sample: HealthSample) -> Bool
    {
        return previousSample.identifier == sample.identifier && sample.startTime.timeIntervalSince(previousSample.endTime) < minGapAllowedDuration
    }
    
    private func removeSmallUnknownTimeSlots(from timeSlots: [TemporaryTimeSlot]) -> [TemporaryTimeSlot]
    {
        return timeSlots.enumerated().filter
            { currentIndex, timeSlot in
                guard timeSlot.category == .unknown else { return true }
                
                let nextIndex = timeSlots.index(after: currentIndex)
                
                guard nextIndex < timeSlots.endIndex else { return true }
                
                let nextTimeSlot = timeSlots[nextIndex]
                
                if timeSlot.category == .unknown && nextTimeSlot.start.timeIntervalSince(timeSlot.start) < minGapAllowedDuration
                {
                    return false
                }
                return true
            }
            .map({ $0.element })
    }
    
    private func removeSmallCommutesTimeSlots(from timeSlots: [TemporaryTimeSlot]) -> [TemporaryTimeSlot]
    {
        return timeSlots.enumerated().filter
            { currentIndex, timeSlot in
                guard timeSlot.category == .commute else { return true }
                
                let nextIndex = timeSlots.index(after: currentIndex)
                
                guard nextIndex < timeSlots.endIndex else { return true }
                
                let nextTimeSlot = timeSlots[nextIndex]
                
                if timeSlot.category == .commute && nextTimeSlot.start.timeIntervalSince(timeSlot.start) < minimumAllowedCommuteDuration
                {
                    return false
                }
                return true
            }
            .map({ $0.element })
    }
    
    private func toTemporaryTimeSlots(_ samples: [HealthSample]) -> [TemporaryTimeSlot]?
    {
        guard let first = samples.first else { return nil }
        
        switch first.identifier {
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            return makeSlots(fromWalkingAndRunning: samples)
        case HKQuantityTypeIdentifier.distanceCycling.rawValue:
            return makeSlots(fromDistanceCycling: samples)
        case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
            return makeSlots(fromSleepAnalysis: samples)
        default:
            return nil
        }
    }
    
    private func makeSlots(fromWalkingAndRunning walkingAndRunning: [HealthSample]) -> [TemporaryTimeSlot]?
    {
        if walkingAndRunning.isEmpty { return nil }
        
        var slotsToReturn = [TemporaryTimeSlot]()
        
        for sample in walkingAndRunning
        {
            let sampleCategory = sample.categoryBasedOnSpeed(using: fastMovingSpeedThreshold)
            
            guard let lastTimeSlot = slotsToReturn.last
            else
            {
                slotsToReturn.append(TemporaryTimeSlot(start: sample.startTime,
                                                       category: sampleCategory))
                continue
            }
            
            if lastTimeSlot.category != sampleCategory
            {
                slotsToReturn.append(TemporaryTimeSlot(start: sample.startTime,
                                                       category: sampleCategory))
            }
        }
        
        
        if let lastSample = walkingAndRunning.last
        {
            slotsToReturn.append(TemporaryTimeSlot(start: lastSample.endTime,
                                                   category: .unknown))
        }
        
        return slotsToReturn
    }
    
    private func makeSlots(fromDistanceCycling distanceCycling: [HealthSample]) -> [TemporaryTimeSlot]?
    {
        guard
            let firstSample = distanceCycling.first,
            let lastSample = distanceCycling.last
            else { return nil }
        
        return [ TemporaryTimeSlot(start: firstSample.startTime,
                                   category: .commute),
                 TemporaryTimeSlot(start: lastSample.endTime,
                                   category: .unknown) ]
    }
    
    private func makeSlots(fromSleepAnalysis sleepAnalysis: [HealthSample]) -> [TemporaryTimeSlot]?
    {
        if sleepAnalysis.isEmpty { return nil }
        
        var slotsToReturn = [TemporaryTimeSlot]()
        
        slotsToReturn.append(TemporaryTimeSlot(start: sleepAnalysis.first!.startTime,
                                               end: sleepAnalysis.last!.endTime,
                                               smartGuess: nil,
                                               category: .sleep,
                                               location: nil))
        
        let lastSample = sleepAnalysis.last!
        
        slotsToReturn.append(TemporaryTimeSlot(start: lastSample.endTime,
                                               category: .unknown))
        
        return slotsToReturn
    }
}
