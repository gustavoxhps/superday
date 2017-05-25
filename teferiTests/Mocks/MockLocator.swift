import UIKit
import Foundation
@testable import teferi

class MockLocator : ViewModelLocator
{
    var timeService = MockTimeService()
    var metricsService = MockMetricsService()
    var timeSlotService : MockTimeSlotService
    var feedbackService = MockFeedbackService()
    var settingsService = MockSettingsService()
    var locationService = MockLocationService()
    var editStateService = MockEditStateService()
    var smartGuessService = MockSmartGuessService()
    var selectedDateService = MockSelectedDateService()
    var appLifecycleService = MockAppLifecycleService()
    var loggingService = MockLoggingService()
    var healthKitService = MockHealthKitService()
    var notificationService  = MockNotificationService()
    
    init()
    {
        self.timeSlotService = MockTimeSlotService(timeService: self.timeService,
                                                   locationService: self.locationService)
    }

    func getNavigationViewModel(forViewController viewController: UIViewController) -> NavigationViewModel
    {
        let feedbackService = (self.feedbackService as! MailFeedbackService).with(viewController: viewController)
        
        return NavigationViewModel(timeService: self.timeService,
                                       feedbackService: feedbackService,
                                       selectedDateService: self.selectedDateService,
                                       appLifecycleService: self.appLifecycleService)
    }
    
    func getIntroViewModel() -> IntroViewModel {
        return IntroViewModel(settingsService: self.settingsService)
    }
    
    func getOnboardingViewModel() -> OnboardingViewModel
    {
        return OnboardingViewModel(timeService: self.timeService,
                                   timeSlotService: self.timeSlotService,
                                   settingsService: self.settingsService,
                                   appLifecycleService: self.appLifecycleService,
                                   notificationService: self.notificationService)
    }
    
    func getMainViewModel() -> MainViewModel
    {
        return MainViewModel(timeService: self.timeService,
                             metricsService: self.metricsService,
                             timeSlotService: self.timeSlotService,
                             editStateService: self.editStateService,
                             smartGuessService: self.smartGuessService,
                             selectedDateService: self.selectedDateService,
                             settingsService: self.settingsService,
                             appLifecycleService: self.appLifecycleService)
    }
    
    func getPagerViewModel() -> PagerViewModel
    {
        return PagerViewModel(timeService: self.timeService,
                              settingsService: self.settingsService,
                              editStateService: self.editStateService,
                              appLifecycleService: self.appLifecycleService,
                              selectedDateService: self.selectedDateService)
    }
    
    func getTimelineViewModel(forDate date: Date) -> TimelineViewModel
    {
        return TimelineViewModel(date: date,
                                 timeService: self.timeService,
                                 timeSlotService: self.timeSlotService,
                                 editStateService: self.editStateService,
                                 appLifecycleService: self.appLifecycleService,
                                 loggingService: self.loggingService)
    }
    
    func getLocationPermissionViewModel() -> PermissionViewModel
    {
        let viewModel = LocationPermissionViewModel(timeService: self.timeService,
                                                    settingsService: self.settingsService,
                                                    appLifecycleService: self.appLifecycleService)
        
        return viewModel
    }
    
    func getHealthKitPermissionViewModel() -> PermissionViewModel
    {
        let viewModel = HealthKitPermissionViewModel(timeService: self.timeService,
                                                    settingsService: self.settingsService,
                                                    appLifecycleService: self.appLifecycleService,
                                                    healthKitService: self.healthKitService)
        
        return viewModel
    }
    
    func getCalendarViewModel() -> CalendarViewModel
    {
        return CalendarViewModel(timeService: self.timeService,
                                 settingsService: self.settingsService,
                                 timeSlotService: self.timeSlotService,
                                 selectedDateService: self.selectedDateService)
    }
    
    func getDailySummaryViewModel(forDate date: Date) -> DailySummaryViewModel
    {
        let viewModel = DailySummaryViewModel(date: date,
                                              timeService: self.timeService,
                                              timeSlotService: self.timeSlotService,
                                              appLifecycleService: self.appLifecycleService,
                                              loggingService: self.loggingService)
        return viewModel
    }
    
    func getSummaryViewModel() -> SummaryViewModel
    {
        return SummaryViewModel(selectedDateService: self.selectedDateService)
    }
    
    func getSummaryPageViewModel(forDate date: Date) -> SummaryPageViewModel
    {
        return SummaryPageViewModel(date: date,
                                    timeService: self.timeService,
                                    settingsService: self.settingsService)
    }
}
