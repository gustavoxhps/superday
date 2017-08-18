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
        scheduleNotification(date: date, title: title, message: message, ofType: .normal)
    }
    
    func scheduleVotingNotifications()
    {
        for i in 2...7
        {
            scheduleNotification(date: Date.create(weekday: i, hour: Constants.hourToShowDailyVotingUI, minute: 00, second: 00), title: L10n.votingNotificationTittle, message: L10n.votingNotificationMessage, ofType: .repeatWeekly)
        }
    }
    
    private func scheduleNotification(date: Date, title: String, message: String, ofType type: NotificationType)
    {
        schedulings += 1
        scheduledNotifications += 1
    }
    
    func unscheduleAllNotifications(ofTypes types: NotificationType?...)
    {
        cancellations += 1
        scheduledNotifications = 0
    }
}
