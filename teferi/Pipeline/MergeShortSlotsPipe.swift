import Foundation

class MergeShortTimeSlotsPipe : Pipe
{
    private let shortTimeSlotThreshold: TimeInterval = 5 * 60

    func process(timeline: [TemporaryTimeSlot]) -> [TemporaryTimeSlot]
    {
        guard timeline.count > 1 else { return timeline }
        
        var auxTimeline = timeline
        var shortestSlotIndex = findShortestSlotIndexSkipingLast(auxTimeline)
        var shortestSlot = auxTimeline[shortestSlotIndex]
        
        while shortestSlot.duration != nil && shortestSlot.duration! < shortTimeSlotThreshold && auxTimeline.count > 1
        {
            defer {
                shortestSlotIndex = findShortestSlotIndexSkipingLast(auxTimeline)
                shortestSlot = auxTimeline[shortestSlotIndex]
            }
            
            guard shortestSlotIndex + 1 < auxTimeline.count,
                areConsecutive(shortestSlot, auxTimeline[shortestSlotIndex + 1]) else
            {
                auxTimeline.remove(at: shortestSlotIndex)
                
                if shortestSlotIndex > 0 && areConsecutive(auxTimeline[shortestSlotIndex - 1], shortestSlot)
                {
                    auxTimeline[shortestSlotIndex - 1] = auxTimeline[shortestSlotIndex - 1].with(end: shortestSlot.end)
                }
                
                continue
            }
            
            let mergedSlot = bestMerge(shortestSlot, auxTimeline[shortestSlotIndex + 1])
            
            auxTimeline[shortestSlotIndex] = mergedSlot
            auxTimeline.remove(at: shortestSlotIndex + 1)
        }
        
        return auxTimeline
    }
    
    private func findShortestSlotIndexSkipingLast(_ timeline: [TemporaryTimeSlot]) -> Int
    {
        var shortestDuration: TimeInterval = TimeInterval.greatestFiniteMagnitude
        var shortestIndex: Int = 0
        for (index, ts) in timeline.dropLast().enumerated()
        {
            guard let duration = ts.duration else
            {
                continue
            }
            
            if duration < shortestDuration
            {
                shortestIndex = index
                shortestDuration = duration
            }
        }
        
        return shortestIndex
    }
    
    private func areConsecutive(_ ts1: TemporaryTimeSlot, _ ts2: TemporaryTimeSlot) -> Bool
    {
        guard let ts1End = ts1.end else { return false }
        return ts2.start == ts1End
    }
    
    private func bestMerge(_ ts1: TemporaryTimeSlot, _ ts2: TemporaryTimeSlot) -> TemporaryTimeSlot
    {
        switch (ts1.smartGuess, ts2.smartGuess) {
        
        case (nil, nil):
            return mergeSlots(ts1, ts2)

        case (_, nil):
            return ts1.with(end: ts2.end)
        
        case (nil, _):
            return ts2.with(start: ts1.start)
            
        case (_, _):
            return bestLocationSlot(ts1, ts2)

        }
    }
    
    private func bestLocationSlot (_ ts1:TemporaryTimeSlot, _ ts2: TemporaryTimeSlot) -> TemporaryTimeSlot
    {
        guard let lc1 = ts1.location else { return ts2.with(start: ts1.start) }
        guard let lc2 = ts2.location else { return ts1.with(end: ts2.end) }
        
        if lc1.horizontalAccuracy < lc2.horizontalAccuracy
        {
            return ts1.with(end: ts2.end)
        }
        
        return ts2.with(start: ts1.start)
    }
    
    private func mergeSlots(_ ts1:TemporaryTimeSlot, _ ts2: TemporaryTimeSlot) -> TemporaryTimeSlot
    {
        let location: Location
        let category: Category
        
        switch (ts1.location, ts2.location) {
        
        case (nil, nil):
            return bestCategorySlot(ts1, ts2)
        
        case let (l1, nil):
           location = l1!
           category = ts1.category != .unknown ? ts1.category : ts2.category
        
        case let (nil, l2):
            location = l2!
            category = ts2.category != .unknown ? ts2.category : ts1.category

        case let(l1, l2) where l1!.horizontalAccuracy < l2!.horizontalAccuracy:
            location = l1!
            category = ts1.category != .unknown ? ts1.category : ts2.category

        //This is the default case: case let(l1, l2) where l1!.horizontalAccuracy > l2!.horizontalAccuracy:
        default:
            location = ts2.location!
            category = ts2.category != .unknown ? ts2.category : ts1.category
        }
        
        return ts1.with(end: ts2.end, smartGuess: nil, category: category, location: location)
    }
    
    private func bestCategorySlot(_ ts1: TemporaryTimeSlot, _ ts2: TemporaryTimeSlot) -> TemporaryTimeSlot
    {
        guard ts1.category != .unknown else { return ts2.with(start: ts1.start) }
        guard ts2.category != .unknown else { return ts1.with(end: ts2.end) }
        
        if ts1.duration ?? 0 > ts2.duration ?? 0
        {
            return ts1.with(end: ts2.end)
        }
        
        return ts2.with(start: ts1.start)
    }
}
