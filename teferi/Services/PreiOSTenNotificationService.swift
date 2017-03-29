import Foundation
import RxSwift
import UIKit

class PreiOSTenNotificationService : NotificationService
{
    //MARK: Fields
    private let loggingService : LoggingService
    private var notificationSubscription : Disposable?
    private let notificationAuthorizedObservable : Observable<Void>
    
    //MARK: Initializers
    init(loggingService: LoggingService, _ notificationAuthorizedObservable: Observable<Void>)
    {
        self.loggingService = loggingService
        self.notificationAuthorizedObservable = notificationAuthorizedObservable
    }
    
    //MARK: NotificationService implementation
    func requestNotificationPermission(completed: @escaping () -> ())
    {
        let notificationSettings = UIUserNotificationSettings(types: [ .alert, .sound, .badge ], categories: nil)
        
        self.notificationSubscription =
            self.notificationAuthorizedObservable
                .subscribe(onNext: completed)
        
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
    }
    
    func scheduleNormalNotification(date: Date, title: String, message: String)
    {
        scheduleNotification(date: date, title: title, message: message, possibleFutureSlotStart: nil, ofType: .normal)
    }
    
    func scheduleCategorySelectionNotification(date: Date, title: String, message: String, possibleFutureSlotStart: Date?)
    {
        scheduleNotification(date: date, title: title, message: message, possibleFutureSlotStart: possibleFutureSlotStart, ofType: .categorySelection)
    }
    
    private func scheduleNotification(date: Date, title: String, message: String, possibleFutureSlotStart: Date?, ofType type: NotificationType)
    {
        loggingService.log(withLogLevel: .debug, message: "Scheduling message for date: \(date)")
        
        let notification = UILocalNotification()
        notification.userInfo = ["id": type.rawValue]
        notification.fireDate = date
        notification.alertTitle = title
        notification.alertBody = message
        notification.alertAction = L10n.appName
        notification.soundName = UILocalNotificationDefaultSoundName
        
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    func unscheduleAllNotifications(ofTypes types: NotificationType?...)
    {
        let giveTypes = types.flatMap { $0 }
        
        guard
            let notifications = UIApplication.shared.scheduledLocalNotifications,
            !giveTypes.isEmpty
        else
        {
            UIApplication.shared.cancelAllLocalNotifications()
            return
        }
        
        notifications.forEach { (notification) in
            if let notificationId = notification.userInfo?["id"] as? String,
                let notificationType = NotificationType(rawValue: notificationId),
                giveTypes.contains(notificationType)
            {
                UIApplication.shared.cancelLocalNotification(notification)
            }
        }
    }
    
    func handleNotificationAction(withIdentifier identifier: String?)
    {
    }
    
    func subscribeToCategoryAction(_ action : @escaping (Category) -> ())
    {
    }
}
