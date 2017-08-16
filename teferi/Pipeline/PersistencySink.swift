import CoreLocation

class PersistencySink : Sink
{
    private typealias SmartGuessUpdate = (smartGuess: SmartGuess, time: Date)
    
    private let settingsService : SettingsService
    private let timeSlotService : TimeSlotService
    private let smartGuessService : SmartGuessService
    private let trackEventService : TrackEventService
    private let timeService : TimeService
    private let metricsService:  MetricsService
    
    init(settingsService: SettingsService,
         timeSlotService: TimeSlotService,
         smartGuessService: SmartGuessService,
         trackEventService: TrackEventService,
         timeService: TimeService,
         metricsService: MetricsService)
    {
        self.settingsService = settingsService
        self.timeSlotService = timeSlotService
        self.smartGuessService = smartGuessService
        self.trackEventService = trackEventService
        self.timeService = timeService
        self.metricsService = metricsService
    }
    
    func execute(timeline: [TemporaryTimeSlot])
    {
        if timeline.isEmpty { return }
        
        var lastLocation : CLLocation? = nil
        var smartGuessesToUpdate = [SmartGuessUpdate]()
        
        var firstSlotCreated : TimeSlot? = nil
        
        for temporaryTimeSlot in timeline
        {
            let addedTimeSlot : TimeSlot?
            if let smartGuess = temporaryTimeSlot.smartGuess
            {
                addedTimeSlot = timeSlotService.addTimeSlot(withStartTime: temporaryTimeSlot.start,
                                                                 smartGuess: smartGuess,
                                                                 location: temporaryTimeSlot.location?.toCLLocation())
                
                smartGuessesToUpdate.append((smartGuess, temporaryTimeSlot.start))
                
                if firstSlotCreated == nil { firstSlotCreated = addedTimeSlot }
            }
            else
            {
                addedTimeSlot = timeSlotService.addTimeSlot(withStartTime: temporaryTimeSlot.start,
                                                                 category: temporaryTimeSlot.category,
                                                                 categoryWasSetByUser: false,
                                                                 location: temporaryTimeSlot.location?.toCLLocation())

                if firstSlotCreated == nil { firstSlotCreated = addedTimeSlot }
            }
            
            lastLocation = addedTimeSlot?.location ?? lastLocation
        }

        logTimeSlotsSince(date: firstSlotCreated?.startTime)
        
        updateIfNeeded(lastLocation: lastLocation)
        smartGuessesToUpdate.forEach { self.smartGuessService.markAsUsed($0.smartGuess, atTime: $0.time) }
        
        trackEventService.clearAllData()
    }
    
    private func logTimeSlotsSince(date: Date?)
    {
        guard let startDate = date else { return }
        
        timeSlotService.getTimeSlots(betweenDate: startDate, andDate: timeService.now).forEach({ slot in
            print(slot)
            metricsService.log(event: .timeSlotCreated(date: timeService.now, category: slot.category, duration: slot.duration))
            if let _ = slot.smartGuessId
            {
                metricsService.log(event: .timeSlotSmartGuessed(date: timeService.now, category: slot.category, duration: slot.duration))
            } else {
                metricsService.log(event: .timeSlotNotSmartGuessed(date: timeService.now, category: slot.category, duration: slot.duration))
            }
        })
    }
    
    private func updateIfNeeded(lastLocation: CLLocation?)
    {
        guard let lastLocation = lastLocation else { return }
        
        settingsService.setLastLocation(lastLocation)
    }
}
