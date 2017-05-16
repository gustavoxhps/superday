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
        self.dateLabel.textColor = UIColor.black
        
        self.activityView.update(dailyActivity: dailyActivity)
        
        self.backgroundView.alpha = 1.0
        self.backgroundView.backgroundColor = UIColor.clear
        
        if isSelected
        {
            self.clipsToBounds = true
            self.backgroundView.alpha = 0.24
            self.backgroundView.layer.cornerRadius = 14
            self.backgroundView.backgroundColor = Style.Color.gray

            self.dateLabel.font = UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightMedium)
        }
    }
}
