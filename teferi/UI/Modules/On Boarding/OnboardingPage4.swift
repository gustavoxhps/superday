import UIKit
import RxSwift

class OnboardingPage4 : OnboardingPage
{
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder, nextButtonText: nil)
    }
    
    override func startAnimations()
    {
        notificationService.requestNotificationPermission(completed:
        { [unowned self] in
            self.finish()
        })
    }
}
