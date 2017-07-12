import Foundation
import RxSwift
import CoreLocation

class OnboardingPageViewModel: NSObject
{
    var movedToForegroundObservable: Observable<Void> {
        return appLifecycleService.movedToForegroundObservable
    }
    
    var locationAuthorizationChangedObservable: Observable<Void>
    {
        return locationAuthorizationSubject.asObservable()
    }
    
    private var timeService : TimeService!
    private var timeSlotService : TimeSlotService!
    fileprivate var settingsService : SettingsService!
    private var appLifecycleService : AppLifecycleService!
    private var notificationService : NotificationService!
    
    fileprivate var locationManager: CLLocationManager!
    fileprivate var locationAuthorizationSubject = PublishSubject<Void>()
    
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
    
    func timelineItem(forTimeslot timeslot: TimeSlot) -> TimelineItem
    {
        let duration = timeSlotService.calculateDuration(ofTimeSlot: timeslot)
        return TimelineItem(timeSlot: timeslot,
                            durations:[ duration ],
                            lastInPastDay: false,
                            shouldDisplayCategoryName: true)
    }
    
    func timeSlot(withCategory category: Category, from: String, to: String) -> TimeSlot
    {
        let startTime = time(from: from)
        let endTime = time(from: to)
        
        let timeSlot = TimeSlot(withStartTime: startTime,
                                endTime: endTime,
                                category: category,
                                categoryWasSetByUser: false)
        
        return timeSlot
    }
    
    func requestNotificationPermission(_ completed:@escaping ()->())
    {
        notificationService.requestNotificationPermission(completed: completed)
    }
    
    func requestLocationAuthorization()
    {
        guard !settingsService.hasLocationPermission else { return }
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    private func time(from timeString: String) -> Date
    {
        guard let hours = Int(timeString.components(separatedBy: ":")[0]),
            let minutes = Int(timeString.components(separatedBy: ":")[1]) else {
                return timeService.now.ignoreTimeComponents()
        }
        
        return timeService.now
            .ignoreTimeComponents()
            .addingTimeInterval(TimeInterval((hours * 60 + minutes) * 60))
    }
}

extension OnboardingPageViewModel: CLLocationManagerDelegate
{
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        if status == .authorizedAlways || status == .denied
        {
            if status == .authorizedAlways {
                settingsService.setUserGaveLocationPermission()
            }
            
            locationManager.delegate = nil
            locationAuthorizationSubject.onNext(())
        }
    }
}
