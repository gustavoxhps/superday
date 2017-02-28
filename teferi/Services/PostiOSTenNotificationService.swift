import Foundation
import UIKit
import UserNotifications

@available(iOS 10.0, *)
class PostiOSTenNotificationService : NotificationService
{
    //MARK: Fields
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
    
    let formatter : DateFormatter =
    {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private var actionSubsribers = [(Category) -> ()]()
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
        content.sound = UNNotificationSound(named: UILocalNotificationDefaultSoundName)
        
        //We shouldn't try guessing which categories the user will pick before we have enough data
        guard self.appIsBeingUsedForOverAWeek else
        {
            self.finishScheduling(date, content)
            return
        }
        
        let numberOfSlotsForNotification : Int = 3
        
        let latestTimeSlots =
            self.timeSlotService
                .getTimeSlots(forDay: self.timeService.now)
                .suffix(numberOfSlotsForNotification)
        
        var latestTimeSlotsForNotification = latestTimeSlots.map(toDictionary)
        
        if let possibleFutureSlotStart = possibleFutureSlotStart
        {
            if latestTimeSlots.count > numberOfSlotsForNotification - 1
            {
                latestTimeSlotsForNotification.removeFirst()
            }
            
            latestTimeSlotsForNotification.append( ["date": formatter.string(from: possibleFutureSlotStart)] )
        }
        
        content.categoryIdentifier = Constants.notificationCategoryId
        content.userInfo = ["timeSlots": latestTimeSlotsForNotification]
        
        self.finishScheduling(date, content)
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
    
    private func finishScheduling(_ date: Date, _ content: UNMutableNotificationContent)
    {
        let fireTime = date.timeIntervalSinceNow
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireTime, repeats: false)
        
        let identifier = String(date.timeIntervalSince1970)
        let request  = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        self.notificationCenter.add(request) { (error) in
            if let error = error
            {
                self.loggingService.log(withLogLevel: .error, message: "Tried to schedule notifications, but could't. Got error: \(error)")
            }
            else
            {
                self.setUserNotificationActions()
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
    
    func setUserNotificationActions()
    {
        guard self.appIsBeingUsedForOverAWeek else { return }

        let desiredNumberOfCategories = 4
        var mostUsedCategories =
            self.timeSlotService
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
