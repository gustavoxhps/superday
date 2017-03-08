import UIKit
import JTAppleCalendar

class CalendarCell : JTAppleDayCellView
{
    @IBOutlet weak var dateLabel : UILabel!
    @IBOutlet weak var activityView : CalendarDailyActivityView!
    @IBOutlet weak var backgroundView: UIView!
    
    private let fontSize = CGFloat(14.0)
    
    func reset(allowScrollingToDate: Bool)
    {
        self.clipsToBounds = true
        self.backgroundColor = UIColor.clear
        self.backgroundView.layer.cornerRadius = 0
        self.backgroundView.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = allowScrollingToDate
        
        self.dateLabel.text = ""
        self.dateLabel.textColor = UIColor.black
        self.dateLabel.font = UIFont.systemFont(ofSize: fontSize)
        
        self.activityView.reset()
    }
    
    func bind(toDate date: Date, isSelected: Bool, allowsScrollingToDate: Bool, dailyActivity: [Activity]?)
    {
        self.reset(allowScrollingToDate: allowsScrollingToDate)
        
        self.dateLabel.text = String(date.day)
        
        self.activityView.update(dailyActivity: dailyActivity)
        
        self.dateLabel.textColor = UIColor.black
        
        if isSelected
        {
            self.clipsToBounds = true
            self.backgroundView.layer.cornerRadius = 14
            self.backgroundView.backgroundColor = Color.lightGray
            self.dateLabel.font = UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightMedium)
        }
    }
}
