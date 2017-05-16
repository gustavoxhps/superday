import UIKit

class DailySummaryTableViewCell: UITableViewCell
{
    @IBOutlet weak var dot: UIView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    private let hourMask = "%02d h %02d min"
    private let minuteMask = "%02d min"
    
    func setup(with activity: Activity, totalDuration: TimeInterval)
    {
        dot.backgroundColor = activity.category.color
        dot.layer.cornerRadius = dot.bounds.width / 2
        
        categoryLabel.text = activity.category.description
        percentageLabel.text = "\(Int(activity.duration / totalDuration * 100))%"
        
        let minutes = (Int(activity.duration) / 60) % 60
        let hours = Int(activity.duration / 3600)
        
        durationLabel.text = hours > 0 ? String(format: hourMask, hours, minutes) : String(format: minuteMask, minutes)
    }
}
