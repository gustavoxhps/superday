import Foundation
import UIKit
import UserNotifications

@available(iOS 10.0, *)
class PostiOSTenNotificationService : NotificationService
{
    //MARK: Fields
    private let timeService : TimeService
    private let loggingService : LoggingService
    private let timeSlotService : TimeSlotService
    
    private var actionSubsribers = [(Category) -> ()]()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    //MARK: Initializers
    init(timeService: TimeService, loggingService: LoggingService, timeSlotService : TimeSlotService)
    {
        self.timeService = timeService
        self.loggingService = loggingService
        self.timeSlotService = timeSlotService
    }
    
    //MARK: NotificationService implementation
    func requestNotificationPermission(completed: @escaping () -> ())
    {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge],
                                                completionHandler: { (granted, error) in completed() })
    }
    
    func scheduleNotification(date: Date, title: String, message: String, possibleFutureSlotStart: Date?)
    {
        self.loggingService.log(withLogLevel: .debug, message: "Scheduling message for date: \(date)")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.categoryIdentifier = Constants.notificationTimeSlotCategorySelectionIdentifier
        content.sound = UNNotificationSound(named: UILocalNotificationDefaultSoundName)
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let numberOfSlotsForNotification : Int = 3
        
        let latestTimeSlots =
            self.timeSlotService
                .getTimeSlots(forDay: self.timeService.now)
                .suffix(numberOfSlotsForNotification)
        
        var latestTimeSlotsForNotification = latestTimeSlots.map { (timeSlot) -> [String: String] in
            
            var timeSlotDictionary = [String: String]()
            
            timeSlotDictionary["color"] = timeSlot.category.color.hexString
            
            if timeSlot.category != .unknown {
                timeSlotDictionary["category"] = timeSlot.category.name
            }
            
            timeSlotDictionary["date"] = formatter.string(from: timeSlot.startTime)
            return timeSlotDictionary
        }
        
        if let possibleFutureSlotStart = possibleFutureSlotStart
        {
            if latestTimeSlots.count > numberOfSlotsForNotification - 1
            {
                latestTimeSlotsForNotification.removeFirst()
            }
            
            latestTimeSlotsForNotification.append( ["date": formatter.string(from: possibleFutureSlotStart)] )
        }
        
        content.userInfo = ["timeSlots": latestTimeSlotsForNotification]
        
        let fireTime = date.timeIntervalSinceNow
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireTime, repeats: false)
        
        let identifier = String(date.timeIntervalSince1970)
        
        let request  = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            if let error = error
            {
                self.loggingService.log(withLogLevel: .error, message: "Tried to schedule notifications, but could't. Got error: \(error)")
            }
        }
    }
    
    func unscheduleAllNotifications()
    {
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func handleNotificationAction(withIdentifier identifier: String?)
    {
        guard let identifier = identifier, let category = Category(rawValue: identifier) else { return }
        
        self.actionSubsribers.forEach { action in action(category) }
    }
    
    func subscribeToCategoryAction(_ action : @escaping (Category) -> ())
    {
        self.actionSubsribers.append(action)
    }
    
    // MARK: - User Notification Action
    func setUserNotificationActions()
    {
        let food = UNNotificationAction(
            identifier: Category.food.rawValue,
            title: Category.food.name)
        
        let friends = UNNotificationAction(
            identifier: Category.friends.rawValue,
            title: Category.friends.name)
        
        let work = UNNotificationAction(
            identifier: Category.work.rawValue,
            title: Category.work.name)
        
        let leisure = UNNotificationAction(
            identifier: Category.leisure.rawValue,
            title: Category.leisure.name)
        
        let category = UNNotificationCategory(
            identifier: Constants.notificationTimeSlotCategorySelectionIdentifier,
            actions: [food, friends, work, leisure],
            intentIdentifiers: [])
        
        notificationCenter.setNotificationCategories([category])
    }
}
