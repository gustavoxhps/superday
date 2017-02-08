import UIKit

class TimeSlotMiniView : UIView
{
    // MARK: - Properties
    @IBOutlet weak var categoryAndTimeLabel: UILabel!
    @IBOutlet weak var colorView: UIView!
    
    class func instanceFromNib() -> TimeSlotMiniView
    {
        return UINib(nibName: "TimeSlotMiniView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! TimeSlotMiniView
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.colorView.layer.cornerRadius = colorView.frame.width / 2
    }
    
    func setUI(_ color : UIColor, category name : String?, date dateString: String)
    {
        self.colorView.backgroundColor = color
        
        let attributedString = NSMutableAttributedString()
        
        if let name = name
        {
            let attributedName = NSAttributedString(string: name + " ", attributes: [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 17), NSForegroundColorAttributeName: UIColor.black])
            attributedString.append(attributedName)
        }
        
        let attributedDate = NSAttributedString(string: dateString, attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 17), NSForegroundColorAttributeName: UIColor.darkGray])
        attributedString.append(attributedDate)
        
        self.categoryAndTimeLabel.attributedText = attributedString
    }

}
