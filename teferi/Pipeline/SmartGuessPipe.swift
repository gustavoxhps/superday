class SmartGuessPipe : Pipe
{
    private let smartGuessService : SmartGuessService
    
    init(smartGuessService: SmartGuessService)
    {
        self.smartGuessService = smartGuessService
    }
    
    func process(timeline: [TemporaryTimeSlot]) -> [TemporaryTimeSlot]
    {
        return timeline
            .map(guessCategory)
    }
    
    private func guessCategory(timeSlot: TemporaryTimeSlot) -> TemporaryTimeSlot
    {
        guard timeSlot.category == .unknown,
            let location = timeSlot.location,
            let smartGuess = smartGuessService.get(forLocation: location.toCLLocation())
            else
        {
                return timeSlot
        }
        
        return timeSlot.with(smartGuess: smartGuess, category: smartGuess.category)
    }
}
