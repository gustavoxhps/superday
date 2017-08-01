import UIKit

class WelcomeView: UIView
{
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subTitleLabel: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        titleLabel.text = L10n.welcomeMessageTitle
        subTitleLabel.text = L10n.welcomeMessageSubTitle
    }
}
