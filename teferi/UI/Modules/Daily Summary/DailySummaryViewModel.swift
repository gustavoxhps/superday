import Foundation

class DailySummaryViewModel
{
    // MARK: Public Properties
    let date : Date
    lazy var activities : [Activity] =
        {
            return self.timeSlotService
                .getActivities(forDate: self.date)
                .sorted(by: self.duration)
    }()
    
    // MARK: Private Properties
    private let timeService : TimeService
    private let timeSlotService : TimeSlotService
    private let appLifecycleService : AppLifecycleService
    private let loggingService : LoggingService
    
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
    private func duration(_ element1: Activity, _ element2: Activity) -> Bool
    {
        return element1.duration > element2.duration
    }
}
