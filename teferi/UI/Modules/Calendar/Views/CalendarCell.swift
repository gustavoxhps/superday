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
        clipsToBounds = true
        backgroundColor = UIColor.clear
        backgroundView.layer.cornerRadius = 0
        backgroundView.backgroundColor = UIColor.clear
        isUserInteractionEnabled = allowScrollingToDate
        
        dateLabel.text = ""
        dateLabel.textColor = UIColor.black
        dateLabel.font = UIFont.systemFont(ofSize: fontSize)
        
        activityView.reset()
    }
    
    func bind(toDate date: Date, isSelected: Bool, allowsScrollingToDate: Bool, dailyActivity: [Activity]?)
    {
        reset(allowScrollingToDate: allowsScrollingToDate)
        
        dateLabel.text = String(date.day)
        dateLabel.textColor = UIColor.black
        
        activityView.update(dailyActivity: dailyActivity)
        
        backgroundView.alpha = 1.0
        backgroundView.backgroundColor = UIColor.clear
        
        if isSelected
        {
            clipsToBounds = true
            backgroundView.alpha = 0.24
            backgroundView.layer.cornerRadius = 14
            backgroundView.backgroundColor = Style.Color.gray

            dateLabel.font = UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightMedium)
        }
    }
}
