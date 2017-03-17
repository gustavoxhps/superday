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
                        .sorted(by: time)
                        .reduce([TemporaryTimeSlot](), self.toSingleTimeline(using: timelines))
        
        return timeline
    }
    
    private func toSingleTimeline(using timelines: [[TemporaryTimeSlot]]) -> ([TemporaryTimeSlot], Date) -> [TemporaryTimeSlot]
    {
        return { timeline, currentTime in
            
            var result = timeline
        
            let intersectedTimeSlots = timelines.flatMap(self.toFirstTimeSlot(thatIntersects: currentTime))
            let category =  intersectedTimeSlots.reduce(Category.unknown, self.categoryOfIntersectedTimeslots)
        
            if let previousTimeSlot = result.last
            {
                var result = result.dropLast()
                result.append(previousTimeSlot.with(end: currentTime))
            }
        
            result.append(TemporaryTimeSlot(start: currentTime,
                                            end: nil,
                                            smartGuess: intersectedTimeSlots.reduce(nil, self.firstValidSmartGuess),
                                            category: category,
                                            location: intersectedTimeSlots.reduce(nil, self.firstValidLocation)))
            
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
    
    private func time(lhs: Date, rhs: Date) -> Bool
    {
        return lhs > rhs
    }
    
    private func categoryOfIntersectedTimeslots(currentCategory: Category, timeSlot: TemporaryTimeSlot) -> Category
    {
        guard currentCategory != .commute else { return currentCategory }
        
        if currentCategory == .unknown
        {
            return timeSlot.smartGuess?.category ?? timeSlot.category
        }
        
        //TODO: Returning unknown when categories clash. will break if we add a third source
        // We need to find a better way of handling it
        return .unknown
    }
    
    private func firstValidSmartGuess(currentSmartGuess: SmartGuess?, timeSlot: TemporaryTimeSlot) -> SmartGuess?
    {
        if currentSmartGuess != nil { return currentSmartGuess }
        
        return timeSlot.smartGuess
    }
    
    private func firstValidLocation(currentLocation: Location?, timeSlot: TemporaryTimeSlot) -> Location?
    {
        if currentLocation != nil { return currentLocation }
        
        return timeSlot.location
    }
}
