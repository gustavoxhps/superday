import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension
{
    // MARK: - Properties
    @IBOutlet weak var stackView: UIStackView!
    
    @available(iOS 10.0, *)
    func didReceive(_ notification: UNNotification)
    {

        if let timeSlots = notification.request.content.userInfo["timeSlots"] as? [[String: String]]
        {
            for timeSlot in timeSlots
            {
                var color = UIColor.gray
                var category: String?
                var date = String()
                
                if let colorHex = timeSlot["color"]
                {
                    color = UIColor(hexString: colorHex)
                }
                
                if let categoryString = timeSlot["category"]
                {
                    category = categoryString
                }
                
                if let dateString = timeSlot["date"]
                {
                    date = dateString
                }
                
                let timeSlotView = TimeSlotMiniView.instanceFromNib()
                timeSlotView.setUI(color, category: category, date: date)
                self.stackView.addArrangedSubview(timeSlotView)
            }
            
            if let lastSlotView = stackView.arrangedSubviews.last as? TimeSlotMiniView
            {
                UIView.animate(withDuration: 0.5,
                               delay: 0,
                               options: [.autoreverse, .repeat],
                               animations: { lastSlotView.colorView.transform = CGAffineTransform(scaleX: 1.4, y: 1.4) },
                               completion: nil)
            }
        }
    }
}
