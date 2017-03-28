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
    
    func process(data: [TemporaryTimeSlot]) -> [TemporaryTimeSlot]
    {
        let now = self.timeService.now
        
        //Creates an empty TimeSlot if there are no TimeSlots for today
        guard data.isEmpty && self.timeSlotService.getTimeSlots(forDay: now).isEmpty else { return data }
        
        return [ TemporaryTimeSlot(start: now) ]
    }
}
