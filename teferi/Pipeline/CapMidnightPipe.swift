import Foundation

class CapMidnightPipe : Pipe
{
    private let timeService : TimeService
    
    init(timeService: TimeService)
    {
        self.timeService = timeService
    }
    
    func process(timeline: [TemporaryTimeSlot]) -> [TemporaryTimeSlot]
    {
        var newTimeline = [TemporaryTimeSlot]()
        
        timeline.forEach { slot in
            
            let end = slot.end ?? timeService.now
            if slot.start.day != end.day
            {
                newTimeline.append( slot.with(end: end.ignoreTimeComponents()) )
                newTimeline.append( slot.with(start: end.ignoreTimeComponents(), end: slot.end) )
            }
            else
            {
                newTimeline.append(slot)
            }
        }
        
        return newTimeline
    }
}
