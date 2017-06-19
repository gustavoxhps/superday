import Foundation

class OnboardingViewModel
{
    private(set) var timeService : TimeService
    private(set) var timeSlotService : TimeSlotService
    private(set) var settingsService : SettingsService
    private(set) var appLifecycleService : AppLifecycleService
    private(set) var notificationService : NotificationService
    
    init(timeService: TimeService,
         timeSlotService: TimeSlotService,
         settingsService: SettingsService,
         appLifecycleService: AppLifecycleService,
         notificationService: NotificationService)
    {
        self.timeService = timeService
        self.timeSlotService = timeSlotService
        self.settingsService = settingsService
        self.appLifecycleService = appLifecycleService
        self.notificationService = notificationService
    }
}
