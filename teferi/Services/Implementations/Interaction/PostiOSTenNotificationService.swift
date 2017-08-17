import Foundation
import UIKit
import UserNotifications

@available(iOS 10.0, *)
class PostiOSTenNotificationService : NotificationService
{
    //MARK: Private Properties
    private let timeService : TimeService
    private let loggingService : LoggingService
    private let settingsService : SettingsService
    private let timeSlotService : TimeSlotService
    
    private var appIsBeingUsedForOverAWeek : Bool
    {
        let daysSinceInstallDate : Int
        
        if let installDate = settingsService.installDate
        {
            daysSinceInstallDate = installDate.differenceInDays(toDate: timeService.now)
        }
        else
        {
            daysSinceInstallDate = 0
        }
        
        return daysSinceInstallDate >= 7
    }
    
    private let formatter : DateFormatter =
    {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    //MARK: Initializers
    init(timeService: TimeService,
         loggingService: LoggingService,
         settingsService: SettingsService,
         timeSlotService: TimeSlotService)
    {
        self.timeService = timeService
        self.loggingService = loggingService
        self.settingsService = settingsService
        self.timeSlotService = timeSlotService
    }
    
    //MARK: Public Methods
    func requestNotificationPermission(completed: @escaping () -> ())
    {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge],
                                                completionHandler: { (granted, error) in completed() })
    }
    
    func scheduleNormalNotification(date: Date, title: String, message: String)
    {
        scheduleNotification(date: date, title: title, message: message, ofType: .normal)
    }
    
    func scheduleVotingNotifications()
    {
        for i in 2...7
        {
            let date = Date.create(weekday: i, hour: 18, minute: 00, second: 00)
            scheduleNotification(date: date, title: L10n.votingNotificationTittle, message: L10n.votingNotificationMessage, ofType: .repeatWeekly)
        }
    }
    
    func unscheduleAllNotifications(ofTypes types: NotificationType?...)
    {
        let givenTypes = types.flatMap { $0 }
        
        if givenTypes.isEmpty
        {
            notificationCenter.removeAllDeliveredNotifications()
            notificationCenter.removeAllPendingNotificationRequests()
            return
        }
        
        notificationCenter.getDeliveredNotifications { (notifications) in
            notifications.forEach({ (notification) in
                givenTypes.forEach({ (type) in
                    if notification.request.identifier.contains(type.rawValue)
                    {
                        self.notificationCenter.removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
                    }
                })
            })
        }
        
        notificationCenter.getPendingNotificationRequests { (requests) in
            requests.forEach({ (request) in
                givenTypes.forEach({ (type) in
                    if request.identifier.contains(type.rawValue)
                    {
                        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [request.identifier])
                    }
                })
            })
        }
    }
    
    func setUserNotificationActions()
    {
        guard appIsBeingUsedForOverAWeek else { return }
        
        let desiredNumberOfCategories = 4
        var mostUsedCategories =
            timeSlotService
                .getTimeSlots(sinceDaysAgo: 2)
                .groupBy(category)
                .sorted(by: count)
                .flatMap(intoCategory)
                .prefix(4)
        
        if mostUsedCategories.count != desiredNumberOfCategories
        {
            let defaultCategories : [ Category ] = [ .work, .food, .leisure, .friends ].filter { !mostUsedCategories.contains($0) }
            let missingCategoryCount = desiredNumberOfCategories - mostUsedCategories.count
            
            mostUsedCategories = mostUsedCategories + defaultCategories.prefix(missingCategoryCount)
        }
        
        let notificationCategory = UNNotificationCategory(identifier: Constants.notificationCategoryId,
                                                          actions: mostUsedCategories.map(toNotificationAction),
                                                          intentIdentifiers: [])
        
        notificationCenter.setNotificationCategories([notificationCategory])
    }
    
    //MARK: Private Methods
    private func scheduleNotification(date: Date, title: String, message: String, ofType type: NotificationType)
    {
        loggingService.log(withLogLevel: .info, message: "Scheduling message for date: \(date)")
        
        let content = notificationContent(title: title, message: message)
        let identifier = type.rawValue + "\(date.dayOfWeek)\(date.hour)\(date.minute)\(date.second)"
        var trigger : UNNotificationTrigger! = nil
        
        switch type {
        case .normal:
            let fireTime = date.timeIntervalSinceNow
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireTime, repeats: false)
        case .repeatWeekly:
            let triggerWeekly = Calendar.current.dateComponents([.weekday, .hour, .minute, .second], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerWeekly, repeats: true)
        }
        
        content.userInfo["id"] = identifier
        
        let request  = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { [unowned self] (error) in
            if let error = error
            {
                self.loggingService.log(withLogLevel: .warning, message: "Tried to schedule notifications, but could't. Got error: \(error)")
            }
            else
            {
                self.setUserNotificationActions()
            }
        }
    }
    
    private func notificationContent(title: String, message: String) -> UNMutableNotificationContent
    {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound(named: UILocalNotificationDefaultSoundName)
        return content
    }
    
    private func toDictionary(_ timeSlot: TimeSlot) -> [String: String]
    {
        var timeSlotDictionary = [String: String]()
    
        timeSlotDictionary["color"] = timeSlot.category.color.hexString
        timeSlotDictionary["date"] = formatter.string(from: timeSlot.startTime)
    
        if timeSlot.category != .unknown
        {
            timeSlotDictionary["category"] = timeSlot.category.description
        }
    
        return timeSlotDictionary
    }
    
    private func category(_ timeSlot: TimeSlot) -> Category
    {
        return timeSlot.category
    }
    
    private func count(_ timeSlots: ([TimeSlot], [TimeSlot])) -> Bool
    {
        return timeSlots.0.count > timeSlots.1.count
    }
    
    private func intoCategory(_ timeSlots: [TimeSlot]) -> Category?
    {
        guard let category = timeSlots.first?.category else { return nil }
        
        guard category != .unknown, category != .commute else { return nil }
        
        return category
    }
    
    private func toNotificationAction(from category: Category) -> UNNotificationAction
    {
        return UNNotificationAction(identifier: category.rawValue,
                                    title: category.description)
    }
}
