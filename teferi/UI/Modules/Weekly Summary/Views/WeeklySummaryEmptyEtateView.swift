import UIKit

class WeeklySummaryEmptyStateView: UIView
{
    @IBOutlet private weak var noDataLabel: UILabel!
    @IBOutlet private weak var bottomLeftImageView: UIImageView!
    @IBOutlet private weak var bottomRightImageView: UIImageView!
    @IBOutlet private weak var topRightImageView: UIImageView!
    
    private let rotationAngles = [ 13.0, 0.0, -23.0 ]
    private let categories : [Category] = [ .work, .fitness, .family ]
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        for (index, imageView) in [ bottomLeftImageView!, bottomRightImageView!, topRightImageView! ].enumerated()
        {
            let category = self.categories[index]
            let rotationAngle = self.rotationAngles[index]
            
            let image = UIImage(asset: category.icon)!.withRenderingMode(.alwaysTemplate)
            
            imageView.image = image
            imageView.tintColor = category.color
            imageView.contentMode = .scaleAspectFill
            imageView.transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle * (.pi / 180.0)))
        }
    }
}
