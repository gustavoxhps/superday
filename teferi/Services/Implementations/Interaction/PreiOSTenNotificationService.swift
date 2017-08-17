import Foundation
import RxSwift
import UIKit

class PreiOSTenNotificationService : NotificationService
{
    //MARK: Private Properties
    private let loggingService : LoggingService
    private var notificationSubscription : Disposable?
    private let notificationAuthorizedObservable : Observable<Void>
    
    //MARK: Initializers
    init(loggingService: LoggingService, _ notificationAuthorizedObservable: Observable<Void>)
    {
        self.loggingService = loggingService
        self.notificationAuthorizedObservable = notificationAuthorizedObservable
    }
    
    //MARK: Public Methods
    func requestNotificationPermission(completed: @escaping () -> ())
    {
        let notificationSettings = UIUserNotificationSettings(types: [ .alert, .sound, .badge ], categories: nil)
        
        notificationSubscription =
            notificationAuthorizedObservable
                .subscribe(onNext: completed)
        
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
    }
    
    func scheduleNormalNotification(date: Date, title: String, message: String)
    {
        scheduleNotification(date: date, title: title, message: message, ofType: .normal)
    }
    
    func unscheduleAllNotifications(ofTypes types: NotificationType?...)
    {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    func scheduleVotingNotifications()
    {
        for i in 2...7
        {
            let date = Date.create(weekday: i, hour: Constants.hourToShowDailyVotingUI, minute: 00, second: 00)
            scheduleNotification(date: date, title: L10n.votingNotificationTittle, message: L10n.votingNotificationMessage, ofType: .repeatWeekly)
        }
    }
    
    //MARK: Private Methods
    private func scheduleNotification(date: Date, title: String, message: String, ofType type: NotificationType)
    {
        loggingService.log(withLogLevel: .info, message: "Scheduling message for date: \(date)")
        
        let notification = UILocalNotification()
        notification.userInfo = ["id": type.rawValue + "\(date.dayOfWeek)\(date.hour)\(date.minute)\(date.second)"]
        notification.fireDate = date
        notification.alertTitle = title
        notification.alertBody = message
        notification.alertAction = L10n.appName
        notification.soundName = UILocalNotificationDefaultSoundName
        
        if type == .repeatWeekly
        {
            notification.repeatInterval = .weekOfYear
        }
        
        UIApplication.shared.scheduleLocalNotification(notification)
    }
}
