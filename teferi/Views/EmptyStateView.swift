import UIKit

class EmptyStateView : UITableViewCell
{
    @IBOutlet private weak var topLeftImage : UIImageView!
    @IBOutlet private weak var topRightImage : UIImageView!
    @IBOutlet private weak var bottomLeftImage : UIImageView!
    @IBOutlet private weak var bottomRightImage : UIImageView!
    
    private let rotationAngles = [ 0.0, 0.0, 0.0, -23.0 ]
    private let categories : [Category] = [ .school, .hobby, .fitness, .family ]
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        for (index, imageView) in [ topLeftImage!, topRightImage!, bottomLeftImage!, bottomRightImage! ].enumerated()
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
