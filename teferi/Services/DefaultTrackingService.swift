import CoreLocation
import CoreMotion
import UIKit
import Foundation

/// Default implementation of the TrackingService.
class DefaultTrackingService : TrackingService
{
    // MARK: Fields
    private let significantDistanceThreshold = 100.0
    private let notificationBody = L10n.notificationBody
    private let notificationTitle = L10n.notificationTitle
    private let commuteDetectionLimit = TimeInterval(25 * 60)
    
    private let timeService : TimeService
    private let loggingService : LoggingService
    private let settingsService : SettingsService
    private let timeSlotService : TimeSlotService
    private let smartGuessService : SmartGuessService
    private let notificationService : NotificationService
    
    private var isOnBackground = false
    
    //MARK: Init
    init(timeService: TimeService,
         loggingService: LoggingService,
         settingsService: SettingsService,
         timeSlotService: TimeSlotService,
         smartGuessService: SmartGuessService,
         notificationService: NotificationService)
    {
        self.timeService = timeService
        self.loggingService = loggingService
        self.settingsService = settingsService
        self.timeSlotService = timeSlotService
        self.smartGuessService = smartGuessService
        self.notificationService = notificationService
        
        notificationService.subscribeToCategoryAction(self.onNotificationAction)
    }
    
    //MARK:  TrackingService implementation
    func onLocation(_ location: CLLocation)
    {
        guard self.isOnBackground else { return }
        
        guard let previousLocation = self.settingsService.lastLocation else
        {
            self.settingsService.setLastLocation(location)
            return
        }
        
        guard location.timestamp > previousLocation.timestamp else { return }
        
        guard self.locationsAreSignificantlyDifferent(current: location, previous: previousLocation) else
        {
            if location.isMoreAccurate(than: previousLocation)
            {
                self.settingsService.setLastLocation(location)
                self.loggingService.log(withLogLevel: .debug, message: "Location is more accurate than previous")
            }
            return
        }
        
        self.settingsService.setLastLocation(location)
        
        guard let currentTimeSlot = self.timeSlotService.getLast() else { return }
        
        let scheduleNotification : Bool
        
        if self.isCommute(now: location.timestamp, then: previousLocation.timestamp)
        {
            if currentTimeSlot.startTime == previousLocation.timestamp
            {
                if !currentTimeSlot.categoryWasSetByUser
                {
                    self.timeSlotService.update(timeSlot: currentTimeSlot, withCategory: .commute, setByUser: false)
                }
            }
            else if currentTimeSlot.category != .commute
            {
                self.startCommute(fromLocation: previousLocation)
            }
            scheduleNotification = true
        }
        else
        {
            if currentTimeSlot.startTime < previousLocation.timestamp
            {
                self.persistTimeSlot(withLocation: previousLocation)
            }
            
            //We should keep the coordinates at the startDate.
            let guessedCategory = self.persistTimeSlot(withLocation: location)
            
            //We only schedule notifications if we couldn't guess any category
            scheduleNotification = guessedCategory == .unknown
        }
        
        self.cancelNotification(andScheduleNew: scheduleNotification)
    }
    
    private func locationsAreSignificantlyDifferent(current: CLLocation, previous: CLLocation) -> Bool
    {
        let distance = current.distance(from: previous)
        let isSignificantDistance = distance > self.significantDistanceThreshold
        
        self.loggingService.log(withLogLevel: .debug, message:
            isSignificantDistance
            ? "distance to previous update (\(distance)) is significant"
            : "distance to previous update (\(distance)) is insignificant")
        
        return isSignificantDistance
    }
    
    private func cancelNotification(andScheduleNew scheduleNew : Bool)
    {
        self.notificationService.unscheduleAllNotifications()
        
        guard scheduleNew else { return }
        
        let notificationDate = self.timeService.now.addingTimeInterval(self.commuteDetectionLimit)
        let possibleFutureSlotStart = timeSlotService.getLast()?.category == Category.commute ? settingsService.lastLocation?.timestamp : nil
        self.notificationService.scheduleNotification(date: notificationDate,
                                                      title: self.notificationTitle,
                                                      message: self.notificationBody,
                                                      possibleFutureSlotStart: possibleFutureSlotStart)
    }
    
    private func onNotificationAction(withCategory category : Category)
    {
        self.tryStoppingCommuteRetroactively(at: self.timeService.now)
        
        guard let currentTimeSlot = self.timeSlotService.getLast() else { return }
        self.timeSlotService.update(timeSlot: currentTimeSlot, withCategory: category, setByUser: true)
    }
    
    private func onAppActivates(at time : Date)
    {
        self.tryStoppingCommuteRetroactively(at: time)
    }
    
    private func tryStoppingCommuteRetroactively(at time : Date)
    {
        guard let lastLocation = self.settingsService.lastLocation else { return }
        
        guard
            let currentTimeSlot = self.timeSlotService.getLast(),
            currentTimeSlot.category == .commute,
            currentTimeSlot.startTime < lastLocation.timestamp,
            !self.isCommute(now: time, then: lastLocation.timestamp)
        else { return }
        
        self.persistTimeSlot(withLocation: lastLocation)
    }
    
    private func isCommute(now : Date, then : Date) -> Bool
    {
        return now.timeIntervalSince(then) < self.commuteDetectionLimit
    }
    
    func onLifecycleEvent(_ event: LifecycleEvent)
    {
        if event == .movedToForeground
        {
            self.onAppActivates(at: self.timeService.now)
        }
        
        self.isOnBackground = event == .movedToBackground
    }
    
    private func startCommute(fromLocation location: CLLocation)
    {
        self.timeSlotService.addTimeSlot(withStartTime: location.timestamp, category: .commute, categoryWasSetByUser: false, location: location)
    }
    
    @discardableResult private func persistTimeSlot(withLocation location: CLLocation) -> Category
    {
        let smartGuess = self.smartGuessService.get(forLocation: location)
        
        if let smartGuess = smartGuess
        {
            self.timeSlotService.addTimeSlot(withStartTime: location.timestamp, smartGuess: smartGuess, location: location)
            self.smartGuessService.markAsUsed(smartGuess, atTime: location.timestamp)
        }
        else
        {
            self.timeSlotService.addTimeSlot(withStartTime: location.timestamp, category: .unknown, categoryWasSetByUser: false, location: location)
        }
        
        return smartGuess?.category ?? .unknown
    }
}
