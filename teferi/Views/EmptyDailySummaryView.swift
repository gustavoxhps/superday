import UIKit

class EmptyDailySummaryView: UIView {

    @IBOutlet private weak var familyIcon : UIImageView!
    @IBOutlet private weak var workIcon : UIImageView!
    @IBOutlet private weak var fitnessIcon : UIImageView!
    @IBOutlet private weak var label : UILabel!

    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        label.textColor = Style.Color.offBlack
        
        configureCategoryIcon(imageView: familyIcon, category:.family, angle:-10)
        configureCategoryIcon(imageView: workIcon, category:.work, angle:10)
        configureCategoryIcon(imageView: fitnessIcon, category:.fitness, angle:0)

    }
    
    private func configureCategoryIcon(imageView:UIImageView, category:Category, angle:CGFloat)
    {
        let image = UIImage(asset: category.icon)!.withRenderingMode(.alwaysTemplate)
        
        imageView.image = image
        imageView.tintColor = category.color
        imageView.contentMode = .scaleAspectFill
        imageView.transform = CGAffineTransform(rotationAngle: CGFloat(angle * (.pi / 180.0)))
    }
}
