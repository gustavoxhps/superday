import UIKit

class WeeklySummaryCategoryTableViewCell: UITableViewCell
{
    static let identifier: String = "weeklySummaryCategoryTableViewCell"
    
    @IBOutlet weak var categoryView: UIView!
    @IBOutlet weak var categoryIcon: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var activityWithPercentage: (Activity, Double)?
    {
        didSet
        {
            configure()
        }
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        nameLabel.textColor = Style.Color.offBlack
        percentageLabel.textColor = Style.Color.offBlack
        categoryView.layer.cornerRadius = categoryView.frame.width / 2
    }

    private func configure()
    {
        guard let activityWithPercentage = activityWithPercentage else { return }
        
        let activity = activityWithPercentage.0
        let percentage = activityWithPercentage.1
        
        
        nameLabel.text = activity.category.description
        categoryView.backgroundColor = activity.category.color
        categoryIcon.image = activity.category.icon.image
        
        percentageLabel.text = "\(Int(round(percentage * 100)))%"
        
        timeLabel.attributedText = attributedStringFromTimeInterval(interval: activity.duration)
    }
    
    private func attributedStringFromTimeInterval(interval: TimeInterval) -> NSAttributedString
    {
        let string = stringFromTimeInterval(interval: interval)
        
        let attributedString = NSMutableAttributedString(string: string, attributes: [
            NSForegroundColorAttributeName: Style.Color.gray
            ])
        
        attributedString.addAttribute(NSForegroundColorAttributeName, value: Style.Color.darkGray, range: NSRange(location: 0, length: 5))
        
        return attributedString
    }
    
    private func stringFromTimeInterval(interval: TimeInterval) -> String {
        
        let ti = NSInteger(interval)
        
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        return String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    }
}
