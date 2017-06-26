class FirstTimeSlotOfDayPipe : Pipe
{
    private let timeService : TimeService
    private let timeSlotService : TimeSlotService
    
    init(timeService: TimeService,
         timeSlotService: TimeSlotService)
    {
        self.timeService = timeService
        self.timeSlotService = timeSlotService
    }
    
    func process(timeline: [TemporaryTimeSlot]) -> [TemporaryTimeSlot]
    {
        let now = timeService.now

        let noTimeSlotsExist = timeSlotService.getLast() == nil
        if noTimeSlotsExist
        {
            return timeline + [TemporaryTimeSlot(start: now, category: .leisure)]
        }        
        
        guard !hasTimeSlotsForToday(timeline) && timeSlotService.getTimeSlots(forDay: now).isEmpty else { return timeline }
        
        return timeline + [ TemporaryTimeSlot(start: now) ]
    }
    
    private func hasTimeSlotsForToday(_ timeline: [TemporaryTimeSlot]) -> Bool
    {
        return !timeline.isEmpty && timeline.contains(where: timeSlotStartsToday)
    }
    
    private func timeSlotStartsToday(timeSlot: TemporaryTimeSlot) -> Bool
    {
        return timeSlot.start.ignoreTimeComponents() == timeService.now.ignoreTimeComponents()
    }
}
