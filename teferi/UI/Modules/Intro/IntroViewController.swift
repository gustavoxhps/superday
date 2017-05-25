import UIKit

class IntroViewController: UIViewController
{
    private var presenter : IntroPresenter!
    private var viewModel : IntroViewModel!
    
    private var launchAnim : LaunchAnimationView!
    
    func inject(presenter: IntroPresenter, viewModel: IntroViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        launchAnim = LaunchAnimationView(frame: view.bounds)
        view.addSubview(launchAnim)


        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        launchAnim.animate { [weak self] in
            
            if let strongSelf = self, strongSelf.viewModel.isFirstUse
            {
                strongSelf.presenter.showOnBoarding()
            } else {
                self?.presenter.showMainScreen()
            }
        }
    }
}
