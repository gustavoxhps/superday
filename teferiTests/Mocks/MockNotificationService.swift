import Foundation
@testable import teferi

class MockNotificationService : NotificationService
{
    var schedulings = 0
    var cancellations = 0
    var scheduledNotifications = 0
    var shouldShowFakeTimeSlot : Bool?
    
    var subscriptions : [(teferi.Category) -> ()] = []
    
    func requestNotificationPermission(completed: @escaping () -> ())
    {
        completed()
    }
    
    func scheduleNormalNotification(date: Date, title: String, message: String)
    {
        
    }
    
    func scheduleCategorySelectionNotification(date: Date, title: String, message: String, possibleFutureSlotStart: Date?)
    {
        scheduleNotification(date: date, title: title, message: message, possibleFutureSlotStart: possibleFutureSlotStart, ofType: .categorySelection)
    }
    
    private func scheduleNotification(date: Date, title: String, message: String, possibleFutureSlotStart: Date?, ofType type: NotificationType)
    {
        shouldShowFakeTimeSlot = possibleFutureSlotStart != nil
        schedulings += 1
        scheduledNotifications += 1
    }
    
    func unscheduleAllNotifications(ofTypes types: NotificationType?...)
    {
        cancellations += 1
        scheduledNotifications = 0
    }
    
    func handleNotificationAction(withIdentifier identifier: String?)
    {
        
    }
    
    func subscribeToCategoryAction(_ action : @escaping (teferi.Category) -> ())
    {
        subscriptions.append(action)
    }
    
    
    func sendAction(withCategory category : teferi.Category)
    {
        subscriptions.forEach { $0(category) }
    }
}
