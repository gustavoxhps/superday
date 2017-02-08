import Foundation
import UIKit

protocol ViewModelLocator
{
    func getCalendarViewModel() -> CalendarViewModel
    
    func getMainViewModel() -> MainViewModel
    
    func getPagerViewModel() -> PagerViewModel
    
    func getTimelineViewModel(forDate date: Date) -> TimelineViewModel
    
    func getTopBarViewModel(forViewController viewController: UIViewController) -> TopBarViewModel
}

class DefaultViewModelLocator : ViewModelLocator
{
    private let timeService : TimeService
    private let metricsService : MetricsService
    private let appStateService : AppStateService
    private let feedbackService : FeedbackService
    private let locationService : LocationService
    private let settingsService : SettingsService
    private let timeSlotService : TimeSlotService
    private let editStateService : EditStateService
    private let smartGuessService : SmartGuessService
    private let selectedDateService: SelectedDateService

    init(timeService: TimeService,
         metricsService: MetricsService,
         appStateService: AppStateService,
         feedbackService: FeedbackService,
         locationService: LocationService,
         settingsService: SettingsService,
         timeSlotService: TimeSlotService,
         editStateService: EditStateService,
         smartGuessService: SmartGuessService,
         selectedDateService: SelectedDateService)
    {
        self.timeService = timeService
        self.metricsService = metricsService
        self.appStateService = appStateService
        self.feedbackService = feedbackService
        self.locationService = locationService
        self.settingsService = settingsService
        self.timeSlotService = timeSlotService
        self.editStateService = editStateService
        self.smartGuessService = smartGuessService
        self.selectedDateService = selectedDateService
    }
    
    func getMainViewModel() -> MainViewModel
    {
        let viewModel = MainViewModel(timeService: self.timeService,
                                      metricsService: self.metricsService,
                                      appStateService: self.appStateService,
                                      settingsService: self.settingsService,
                                      timeSlotService: self.timeSlotService,
                                      locationService: self.locationService,
                                      editStateService: self.editStateService,
                                      smartGuessService: self.smartGuessService,
                                      selectedDateService: self.selectedDateService)
        
        return viewModel
    }
    
    func getPagerViewModel() -> PagerViewModel
    {
        let viewModel = PagerViewModel(timeService: self.timeService,
                                       appStateService: self.appStateService,
                                       settingsService: self.settingsService,
                                       editStateService: self.editStateService,
                                       selectedDateService: self.selectedDateService)
        return viewModel
    }

    func getTimelineViewModel(forDate date: Date) -> TimelineViewModel
    {
        let viewModel = TimelineViewModel(date: date,
                                          timeService: self.timeService,
                                          appStateService: self.appStateService,
                                          timeSlotService: self.timeSlotService,
                                          editStateService: self.editStateService)
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
