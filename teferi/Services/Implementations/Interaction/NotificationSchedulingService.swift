import Foundation
import RxSwift
import CoreLocation

class NotificationSchedulingService
{
    private let disposeBag = DisposeBag()
    private let significantDistanceThreshold = 100.0
    private let notificationBody = L10n.notificationBody
    private let notificationTitle = L10n.notificationTitle
    private let commuteDetectionLimit = TimeInterval(25 * 60)
    
    private let timeService : TimeService
    private let settingsService : SettingsService
    private let smartGuessService : SmartGuessService
    private let notificationService : NotificationService
    
    init(timeService: TimeService,
         settingsService: SettingsService,
         locationService: LocationService,
         smartGuessService: SmartGuessService,
         notificationService: NotificationService)
    {
        self.timeService = timeService
        self.settingsService = settingsService
        self.smartGuessService = smartGuessService
        self.notificationService = notificationService
        
        locationService
            .eventObservable
            .map { Location.fromTrackEvent(event: $0)?.toCLLocation() }
            .filterNil()
            .subscribe(onNext: onLocation)
            .addDisposableTo(disposeBag)
        
    }
    
    //MARK:  TrackingService implementation
    func onLocation(_ location: CLLocation)
    {
        guard let previousLocation = settingsService.lastNotificationLocation else
        {
            settingsService.setLastNotificationLocation(location)
            return
        }
        
        guard location.timestamp > previousLocation.timestamp else { return }
        
        guard locationsAreSignificantlyDifferent(current: location, previous: previousLocation) else
        {
            guard location.isMoreAccurate(than: previousLocation) else { return }
            
            settingsService.setLastNotificationLocation(location)
            return
        }
        
        settingsService.setLastNotificationLocation(location)
        
        let scheduleNotification : Bool
        
        if isCommute(now: location.timestamp, then: previousLocation.timestamp)
        {
            scheduleNotification = true
        }
        else
        {
            //We should keep the coordinates at the startDate.
            let guessedCategory = smartGuessService.get(forLocation: location)?.category ?? .unknown
            
            //We only schedule notifications if we couldn't guess any category
            scheduleNotification = guessedCategory == .unknown
        }
        
        cancelNotification(andScheduleNew: scheduleNotification)
    }
    
    private func isCommute(now : Date, then : Date) -> Bool
    {
        return now.timeIntervalSince(then) < commuteDetectionLimit
    }
    
    private func locationsAreSignificantlyDifferent(current: CLLocation, previous: CLLocation) -> Bool
    {
        let distance = current.distance(from: previous)
        let isSignificantDistance = distance > significantDistanceThreshold
        
        return isSignificantDistance
    }
    
    private func cancelNotification(andScheduleNew scheduleNew : Bool)
    {
        notificationService.unscheduleAllNotifications(ofTypes: .categorySelection)
        
        guard scheduleNew else { return }
        
        let notificationDate = timeService.now.addingTimeInterval(commuteDetectionLimit)
        notificationService.scheduleCategorySelectionNotification(date: notificationDate,
                                                                       title: notificationTitle,
                                                                       message: notificationBody,
                                                                       possibleFutureSlotStart: nil)
    }
}
