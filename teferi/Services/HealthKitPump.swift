import Foundation
import HealthKit

class HealthKitPump : Pump
{
    private let trackEventService : TrackEventService
    private let fastMovingSpeedThreshold : Double
    private let minGapAllowedDuration : Double
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
         minGapAllowedDuration: Double = 900,
         loggingService: LoggingService)
    {
        self.trackEventService = trackEventService
        self.fastMovingSpeedThreshold = fastMovingSpeedThreshold
        self.minGapAllowedDuration = minGapAllowedDuration
        self.loggingService = loggingService
    }
    
    // MARK: - Protocol implementation
    func run() -> [TemporaryTimeSlot]
    {
        let groupedHealthSamples = trackEventService
            .getEventData(ofType: HealthSample.self)
            .distinct()
            .sorted(by: { $0.startTime < $1.startTime })
            .splitBy(sameIdAndContinuous)
        
        let temporaryTimeSlots = groupedHealthSamples
            .flatMap(toTemporaryTimeSlots)
            .flatMap { $0 }
                
        let temporaryTimeSlotsToReturn = removeSmallUnknownTimeSlots(from: temporaryTimeSlots)

        self.loggingService.log(withLogLevel: .info, message: "HealthKit pump temporary timeline:")
        temporaryTimeSlotsToReturn.forEach { (slot) in
            self.loggingService.log(withLogLevel: .info, message: "HKTempSlot start: \(slot.start) category: \(slot.category.rawValue)")
        }
        
        return temporaryTimeSlotsToReturn
    }
    
    // MARK: - Helper
    private func sameIdAndContinuous(previousSample:HealthSample, sample:HealthSample) -> Bool
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
        if walkingAndRunning.isEmpty { return nil }
        
        var slotsToReturn = [TemporaryTimeSlot]()
        
        var lastTimeSlot : TemporaryTimeSlot?
        
        for sample in walkingAndRunning
        {
            let sampleCategory = sample.categoryBasedOnSpeed(using: fastMovingSpeedThreshold)
            
            if lastTimeSlot == nil
            {
                slotsToReturn.append(TemporaryTimeSlot(start: sample.startTime,
                                                       end: nil,
                                                       smartGuess: nil,
                                                       category: sampleCategory,
                                                       location: nil))
                lastTimeSlot = slotsToReturn.last
                continue
            }
            
            if let lastTimeSlot = lastTimeSlot, lastTimeSlot.category != sampleCategory
            {
                slotsToReturn.append(TemporaryTimeSlot(start: sample.startTime,
                                                       end: nil,
                                                       smartGuess: nil,
                                                       category: sampleCategory,
                                                       location: nil))
            }
            
            lastTimeSlot = slotsToReturn.last
        }
        
        
        if let lastSample = walkingAndRunning.last
        {
            slotsToReturn.append(TemporaryTimeSlot(start: lastSample.endTime,
                                                   end: nil,
                                                   smartGuess: nil,
                                                   category: .unknown,
                                                   location: nil))
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
                                   end: nil,
                                   smartGuess: nil,
                                   category: .commute,
                                   location: nil),
                 TemporaryTimeSlot(start: lastSample.endTime,
                                   end: nil,
                                   smartGuess: nil,
                                   category: .unknown,
                                   location: nil) ]
    }
    
    private func makeSlots(fromSleepAnalysis sleepAnalysis: [HealthSample]) -> [TemporaryTimeSlot]?
    {
        if sleepAnalysis.isEmpty { return nil }
        
        var slotsToReturn = [TemporaryTimeSlot]()
        
        sleepAnalysis.forEach({ (sample) in
            
            slotsToReturn.append(TemporaryTimeSlot(start: sample.startTime,
                                                   end: nil,
                                                   smartGuess: nil,
                                                   category: .unknown,
                                                   location: nil))
        })
        
        let lastSample = sleepAnalysis.last!
        
        slotsToReturn.append(TemporaryTimeSlot(start: lastSample.endTime,
                                               end: nil,
                                               smartGuess: nil,
                                               category: .unknown,
                                               location: nil))
        
        return slotsToReturn
    }
}
