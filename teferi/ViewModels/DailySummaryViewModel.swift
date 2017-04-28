import Foundation

class DailySummaryViewModel
{
    private let timeService : TimeService
    private let timeSlotService : TimeSlotService
    private let appLifecycleService : AppLifecycleService
    private let loggingService : LoggingService
    
    let date : Date
    lazy var activities : [Activity] =
    {
        return self.timeSlotService
            .getTimeSlots(forDay: self.date)
            .groupBy( { $0.category } )
            .map(self.toActivity)
            .sorted(by: { $0.duration > $1.duration } )
    }()
    
    // MARK: - Init
    init(date: Date,
         timeService: TimeService,
         timeSlotService: TimeSlotService,
         appLifecycleService: AppLifecycleService,
         loggingService: LoggingService)
    {
        self.timeService = timeService
        self.timeSlotService = timeSlotService
        self.appLifecycleService = appLifecycleService
        self.loggingService = loggingService
        self.date = date.ignoreTimeComponents()
    }
    
    // MARK: - Helper
    private func toActivity(_ timeSlots: [TimeSlot]) -> Activity
    {
        let totalTime =
            timeSlots
                .map(timeSlotService.calculateDuration)
                .reduce(0, +)
        
        return Activity(category: timeSlots.first!.category, duration: totalTime)
    }
}
