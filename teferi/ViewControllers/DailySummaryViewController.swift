import UIKit

class DailySummaryViewController: UIViewController {
    
    var viewModel : DailySummaryViewModel!
    var presenter : DailySummaryPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white
    }
}
