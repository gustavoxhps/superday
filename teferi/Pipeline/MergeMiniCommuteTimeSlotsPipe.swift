import Foundation

class MergeMiniCommuteTimeSlotsPipe : Pipe
{
    private enum SlotToMerge
    {
        case usePrevious(timeSlot: TemporaryTimeSlot)
        case useNext(timeSlot: TemporaryTimeSlot)
        case dontMerge
    }
    
    // MARK: Fields
    private let smallTimeSlotThreshold = TimeInterval(8 * 60)
    private let timeService : TimeService
    
    init(timeService: TimeService)
    {
        self.timeService = timeService
    }
    
    func process(timeline: [TemporaryTimeSlot]) -> [TemporaryTimeSlot]
    {
        if timeline.count < 2 { return timeline }
        
        var shouldSkip = false
        let newTimeline = timeline.enumerated().reduce([TemporaryTimeSlot](), { (newTimeline, enumeration) in
        
            if shouldSkip
            {
                shouldSkip = false
                return newTimeline
            }
        
            let currentTimeSlot = enumeration.element
            
            guard currentTimeSlot.category == .commute && self.durationIsBelowThreshold(currentTimeSlot) else
            {
                return newTimeline + [currentTimeSlot]
            }
            
            let previousTimeSlot = newTimeline.last
            let nextTimeSlot = timeline.safeGetElement(at: enumeration.offset + 1)
            
            switch self.selectTimeSlotToMerge(previousTimeSlot, nextTimeSlot)
            {
                case .usePrevious(let previousTimeSlot):
                    return newTimeline.dropLast(1) + [ self.mergeSlots(previousTimeSlot, currentTimeSlot) ]
                
                case .useNext(let nextTimeSlot):
                    shouldSkip = true
                    return newTimeline + [ self.mergeSlots(currentTimeSlot, nextTimeSlot) ]
                
                case .dontMerge:
                    return newTimeline + [ currentTimeSlot ]
            }
        })
        
        return newTimeline
    }
    
    private func durationIsBelowThreshold(_ timeSlot: TemporaryTimeSlot) -> Bool
    {
        let timeSlotDuration = timeSlot.duration ?? self.timeService.now.timeIntervalSince(timeSlot.start)
        return timeSlotDuration <= smallTimeSlotThreshold
    }
    
    private func selectTimeSlotToMerge(_ previousTimeSlot: TemporaryTimeSlot?, _ nextTimeSlot: TemporaryTimeSlot?) -> SlotToMerge
    {
        guard let previousTimeSlot = previousTimeSlot, previousTimeSlot.category == .commute else
        {
            guard let nextTimeSlot = nextTimeSlot, nextTimeSlot.category == .commute else { return .dontMerge }
            
            return .useNext(timeSlot: nextTimeSlot)
        }
        
        guard let nextTimeSlot = nextTimeSlot, nextTimeSlot.category == .commute else
        {
            return .usePrevious(timeSlot: previousTimeSlot)
        }
        
        return self.getSmallerDuration(previousTimeSlot, nextTimeSlot)
    }
    
    private func getSmallerDuration(_ previousTimeSlot: TemporaryTimeSlot, _ nextTimeSlot: TemporaryTimeSlot) -> SlotToMerge
    {
        let previousTimeSlotDuration = previousTimeSlot.duration ?? self.timeService.now.timeIntervalSince(previousTimeSlot.start)
        let nextTimeSlotDuration = nextTimeSlot.duration ?? self.timeService.now.timeIntervalSince(nextTimeSlot.start)
        
        return previousTimeSlotDuration >= nextTimeSlotDuration ? .usePrevious(timeSlot: previousTimeSlot) : .useNext(timeSlot: nextTimeSlot)
    }
    
    private func mergeSlots(_ firstSlot: TemporaryTimeSlot, _ secondSlot: TemporaryTimeSlot) -> TemporaryTimeSlot
    {
        return TemporaryTimeSlot(start: firstSlot.start,
                                 end: secondSlot.end,
                                 smartGuess: secondSlot.smartGuess ?? firstSlot.smartGuess,
                                 category: .commute,
                                 location: secondSlot.location ?? firstSlot.location)
    }
}
