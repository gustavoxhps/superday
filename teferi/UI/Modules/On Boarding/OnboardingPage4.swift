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
        self.notificationService.requestNotificationPermission(completed:
        {
            self.finish()
        })
    }
}
