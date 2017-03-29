import Foundation
import UserNotificationsUI

protocol NotificationService
{
    func requestNotificationPermission(completed: @escaping () -> ())
    
    func scheduleNormalNotification(date: Date, title: String, message: String)
    func scheduleCategorySelectionNotification(date: Date, title: String, message: String, possibleFutureSlotStart: Date?)
    
    func unscheduleAllNotifications(ofTypes types: NotificationType?...)
    
    func handleNotificationAction(withIdentifier identifier: String?)
    
    func subscribeToCategoryAction(_ action : @escaping (Category) -> ())
}
