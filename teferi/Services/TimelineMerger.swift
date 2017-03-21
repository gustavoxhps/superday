import Foundation

class TimelineMerger : TemporaryTimelineGenerator
{
    private let timelineGenerators : [TemporaryTimelineGenerator]
    
    init(withTimelineGenerator timelineGenerators: [TemporaryTimelineGenerator])
    {
        self.timelineGenerators = timelineGenerators
    }
    
    func generateTemporaryTimeline() -> [TemporaryTimeSlot]
    {
        let timelines = self.timelineGenerators
                            .map { $0.generateTemporaryTimeline() }
    
        let flatTimeline = timelines.flatMap { $0 }
        let startTimes =  flatTimeline.map { $0.start }
        let endTimes = flatTimeline.flatMap { $0.end }
        
        let timeline = (startTimes + endTimes)
                        .distinct()
                        .sorted(by: >)
                        .reduce([TemporaryTimeSlot](), self.toSingleTimeline(using: timelines))
        
        return timeline
    }
    
    private func toSingleTimeline(using timelines: [[TemporaryTimeSlot]]) -> ([TemporaryTimeSlot], Date) -> [TemporaryTimeSlot]
    {
        return { timeline, currentTime in
            
            var result = timeline
        
            let intersectedTimeSlots = timelines.flatMap(self.toFirstTimeSlot(thatIntersects: currentTime))
            let bestTimeSlot =  self.getTimeSlotWithBestCategory(inIntersectedTimeslots: intersectedTimeSlots)
        
            if let previousTimeSlot = result.last
            {
                var result = result.dropLast()
                result.append(previousTimeSlot.with(end: currentTime))
            }
        
            result.append(TemporaryTimeSlot(start: currentTime,
                                            end: nil,
                                            smartGuess: bestTimeSlot?.smartGuess,
                                            category: bestTimeSlot?.category ?? .unknown,
                                            location: bestTimeSlot?.location))
            
            return result
        }
    }

    private func toFirstTimeSlot(thatIntersects time: Date) -> ([TemporaryTimeSlot]) -> TemporaryTimeSlot?
    {
        return { timeline in
            do
            {
                let first = timeline.first(where:)
                let timeSlot = try first { timeSlot in return timeSlot.start <= time && (timeSlot.end == nil || timeSlot.end! > time) }
                return timeSlot
            }
            catch
            {
                return nil
            }
        }
    }
    
    private func getTimeSlotWithBestCategory(inIntersectedTimeslots timeSlots: [TemporaryTimeSlot]) -> TemporaryTimeSlot?
    {
        var bestTemporaryTimeSlot : TemporaryTimeSlot?
        
        for timeSlot in timeSlots
        {
            if timeSlot.category == .unknown { continue }
            
            if let currentBest = bestTemporaryTimeSlot
            {
                if currentBest.category == .commute && currentBest.category != .commute { continue }
                
                //If both temporary timeSlots have the same category, we're fine
                if currentBest.category == timeSlot.category { continue }
                
                //If they have different categories, we stick to the one with a SmartGuess
                if currentBest.smartGuess != nil || timeSlot.smartGuess == nil { continue }
            }
            
            bestTemporaryTimeSlot = timeSlot
        }
        
        return bestTemporaryTimeSlot ?? timeSlots.first
    }
}
