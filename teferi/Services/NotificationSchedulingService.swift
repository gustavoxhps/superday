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
            .locationObservable
            .subscribe(onNext: onLocation)
            .addDisposableTo(disposeBag)
        
    }
    
    //MARK:  TrackingService implementation
    func onLocation(_ location: CLLocation)
    {
        guard let previousLocation = self.settingsService.lastNotificationLocation else
        {
            self.settingsService.setLastNotificationLocation(location)
            return
        }
        
        guard location.timestamp > previousLocation.timestamp else { return }
        
        guard self.locationsAreSignificantlyDifferent(current: location, previous: previousLocation) else
        {
            guard location.isMoreAccurate(than: previousLocation) else { return }
            
            self.settingsService.setLastNotificationLocation(location)
            return
        }
        
        self.settingsService.setLastNotificationLocation(location)
        
        let scheduleNotification : Bool
        
        if self.isCommute(now: location.timestamp, then: previousLocation.timestamp)
        {
            scheduleNotification = true
        }
        else
        {
            //We should keep the coordinates at the startDate.
            let guessedCategory = self.smartGuessService.get(forLocation: location)?.category ?? .unknown
            
            //We only schedule notifications if we couldn't guess any category
            scheduleNotification = guessedCategory == .unknown
        }
        
        self.cancelNotification(andScheduleNew: scheduleNotification)
    }
    
    private func isCommute(now : Date, then : Date) -> Bool
    {
        return now.timeIntervalSince(then) < self.commuteDetectionLimit
    }
    
    private func locationsAreSignificantlyDifferent(current: CLLocation, previous: CLLocation) -> Bool
    {
        let distance = current.distance(from: previous)
        let isSignificantDistance = distance > self.significantDistanceThreshold
        
        return isSignificantDistance
    }
    
    private func cancelNotification(andScheduleNew scheduleNew : Bool)
    {
        self.notificationService.unscheduleAllNotifications()
        
        guard scheduleNew else { return }
        
        let notificationDate = self.timeService.now.addingTimeInterval(self.commuteDetectionLimit)
        self.notificationService.scheduleCategorySelectionNotification(date: notificationDate,
                                                                       title: self.notificationTitle,
                                                                       message: self.notificationBody,
                                                                       possibleFutureSlotStart: nil)
    }
}
