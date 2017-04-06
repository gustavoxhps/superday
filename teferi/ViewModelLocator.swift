import Foundation
import UIKit

protocol ViewModelLocator
{
    func getCalendarViewModel() -> CalendarViewModel
    
    func getMainViewModel() -> MainViewModel
    
    func getPagerViewModel() -> PagerViewModel
    
    func getLocationPermissionViewModel() -> PermissionViewModel
    func getHealthKitPermissionViewModel() -> PermissionViewModel
    
    func getTimelineViewModel(forDate date: Date) -> TimelineViewModel
    
    func getTopBarViewModel(forViewController viewController: UIViewController) -> TopBarViewModel
}

class DefaultViewModelLocator : ViewModelLocator
{
    private let timeService : TimeService
    private let metricsService : MetricsService
    private let feedbackService : FeedbackService
    private let locationService : LocationService
    private let settingsService : SettingsService
    private let timeSlotService : TimeSlotService
    private let editStateService : EditStateService
    private let smartGuessService : SmartGuessService
    private let appLifecycleService : AppLifecycleService
    private let selectedDateService : SelectedDateService
    private let healthKitService : HealthKitService

    init(timeService: TimeService,
         metricsService: MetricsService,
         feedbackService: FeedbackService,
         locationService: LocationService,
         settingsService: SettingsService,
         timeSlotService: TimeSlotService,
         editStateService: EditStateService,
         smartGuessService: SmartGuessService,
         appLifecycleService: AppLifecycleService,
         selectedDateService: SelectedDateService,
         healthKitService : HealthKitService)
    {
        self.timeService = timeService
        self.metricsService = metricsService
        self.feedbackService = feedbackService
        self.locationService = locationService
        self.settingsService = settingsService
        self.timeSlotService = timeSlotService
        self.editStateService = editStateService
        self.smartGuessService = smartGuessService
        self.appLifecycleService = appLifecycleService
        self.selectedDateService = selectedDateService
        self.healthKitService = healthKitService
    }
    
    func getMainViewModel() -> MainViewModel
    {
        let viewModel = MainViewModel(timeService: self.timeService,
                                      metricsService: self.metricsService,
                                      timeSlotService: self.timeSlotService,
                                      editStateService: self.editStateService,
                                      smartGuessService: self.smartGuessService,
                                      selectedDateService: self.selectedDateService,
                                      settingsService: self.settingsService)
        return viewModel
    }
    
    func getPagerViewModel() -> PagerViewModel
    {
        let viewModel = PagerViewModel(timeService: self.timeService,
                                       settingsService: self.settingsService,
                                       editStateService: self.editStateService,
                                       appLifecycleService: self.appLifecycleService,
                                       selectedDateService: self.selectedDateService)
        return viewModel
    }

    func getTimelineViewModel(forDate date: Date) -> TimelineViewModel
    {
        let viewModel = TimelineViewModel(date: date,
                                          timeService: self.timeService,
                                          timeSlotService: self.timeSlotService,
                                          editStateService: self.editStateService,
                                          appLifecycleService: self.appLifecycleService)
        return viewModel
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
        let viewModel = CalendarViewModel(timeService: self.timeService,
                                          settingsService: self.settingsService,
                                          timeSlotService: self.timeSlotService,
                                          selectedDateService: self.selectedDateService)
        
        return viewModel
    }
    
    func getTopBarViewModel(forViewController viewController: UIViewController) -> TopBarViewModel
    {
        let feedbackService = (self.feedbackService as! MailFeedbackService).with(viewController: viewController)
        
        let viewModel = TopBarViewModel(timeService: self.timeService,
                                        feedbackService: feedbackService,
                                        selectedDateService: self.selectedDateService)
        
        return viewModel
    }
}
