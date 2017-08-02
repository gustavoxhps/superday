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
        timeSlotService = MockTimeSlotService(timeService: timeService,
                                                   locationService: locationService)
    }

    func getNavigationViewModel(forViewController viewController: UIViewController) -> NavigationViewModel
    {
        let feedbackService = (self.feedbackService as! MailFeedbackService).with(viewController: viewController)
        
        return NavigationViewModel(timeService: timeService,
                                       feedbackService: feedbackService,
                                       selectedDateService: selectedDateService,
                                       appLifecycleService: appLifecycleService)
    }
    
    func getIntroViewModel() -> IntroViewModel
    {
        return IntroViewModel(settingsService: settingsService)
    }
    
    func getOnboardingViewModel() -> OnboardingViewModel
    {
        return OnboardingViewModel(timeService: timeService,
                                   timeSlotService: timeSlotService,
                                   settingsService: settingsService,
                                   appLifecycleService: appLifecycleService,
                                   notificationService: notificationService)
    }
    
    func getMainViewModel() -> MainViewModel
    {
        return MainViewModel(timeService: timeService,
                             metricsService: metricsService,
                             timeSlotService: timeSlotService,
                             editStateService: editStateService,
                             smartGuessService: smartGuessService,
                             selectedDateService: selectedDateService,
                             settingsService: settingsService,
                             appLifecycleService: appLifecycleService)
    }
    
    func getPagerViewModel() -> PagerViewModel
    {
        return PagerViewModel(timeService: timeService,
                              timeSlotService: timeSlotService,
                              settingsService: settingsService,
                              editStateService: editStateService,
                              appLifecycleService: appLifecycleService,
                              selectedDateService: selectedDateService)
    }
    
    func getTimelineViewModel(forDate date: Date) -> TimelineViewModel
    {
        return TimelineViewModel(date: date,
                                 timeService: timeService,
                                 timeSlotService: timeSlotService,
                                 editStateService: editStateService,
                                 appLifecycleService: appLifecycleService,
                                 loggingService: loggingService)
    }
    
    func getLocationPermissionViewModel() -> PermissionViewModel
    {
        let viewModel = LocationPermissionViewModel(timeService: timeService,
                                                    settingsService: settingsService,
                                                    appLifecycleService: appLifecycleService)
        
        return viewModel
    }
    
    func getHealthKitPermissionViewModel() -> PermissionViewModel
    {
        let viewModel = HealthKitPermissionViewModel(timeService: timeService,
                                                    settingsService: settingsService,
                                                    appLifecycleService: appLifecycleService,
                                                    healthKitService: healthKitService)
        
        return viewModel
    }
    
    func getCalendarViewModel() -> CalendarViewModel
    {
        return CalendarViewModel(timeService: timeService,
                                 settingsService: settingsService,
                                 timeSlotService: timeSlotService,
                                 selectedDateService: selectedDateService)
    }
    
    func getWeeklySummaryViewModel() -> WeeklySummaryViewModel
    {
        return WeeklySummaryViewModel(timeService: timeService,
                                      timeSlotService: timeSlotService,
                                      settingsService: settingsService)
    }
    
    func getDailySummaryViewModel(forDate date: Date) -> DailySummaryViewModel
    {
        return DailySummaryViewModel(date: date,
                                     timeService: timeService,
                                     timeSlotService: timeSlotService,
                                     appLifecycleService: appLifecycleService,
                                     loggingService: loggingService)
    }
    
    func getSummaryViewModel() -> SummaryViewModel
    {
        return SummaryViewModel(selectedDateService: selectedDateService)
    }
    
    func getSummaryPageViewModel(forDate date: Date) -> SummaryPageViewModel
    {
        return SummaryPageViewModel(date: date,
                                    timeService: timeService,
                                    settingsService: settingsService)
    }
}
