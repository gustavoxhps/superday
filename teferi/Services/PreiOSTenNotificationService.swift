import Foundation
import RxSwift
import UIKit

class PreiOSTenNotificationService : NotificationService
{
    //MARK: Fields
    private let loggingService : LoggingService
    private var notificationSubscription : Disposable?
    private let notificationAuthorizationObservable : Observable<Bool>
    
    //MARK: Initializers
    init(loggingService: LoggingService, _ notificationAuthorizationObservable: Observable<Bool>)
    {
        self.loggingService = loggingService
        self.notificationAuthorizationObservable = notificationAuthorizationObservable
    }
    
    //MARK: NotificationService implementation
    func requestNotificationPermission(completed: @escaping () -> ())
    {
        let notificationSettings = UIUserNotificationSettings(types: [ .alert, .sound, .badge ], categories: nil)
        
        self.notificationSubscription =
            self.notificationAuthorizationObservable
                .subscribe(onNext: { wasSet in
                    
                    guard wasSet else { return }
                    
                    completed()
                })
        
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
    }
    
    func scheduleNotification(date: Date, title: String, message: String, possibleFutureSlotStart: Date?)
    {
        loggingService.log(withLogLevel: .debug, message: "Scheduling message for date: \(date)")
        
        let notification = UILocalNotification()
        notification.fireDate = date
        notification.alertTitle = title
        notification.alertBody = message
        notification.alertAction = L10n.appName
        notification.soundName = UILocalNotificationDefaultSoundName
        
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    func unscheduleAllNotifications()
    {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    func handleNotificationAction(withIdentifier identifier: String?)
    {
    }
    
    func subscribeToCategoryAction(_ action : @escaping (Category) -> ())
    {
    }
}
