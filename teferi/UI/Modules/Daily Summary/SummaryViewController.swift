import UIKit
import RxSwift

class SummaryViewController: UIViewController
{
    private var disposeBag : DisposeBag = DisposeBag()
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    private var summaryPageViewController : SummaryPageViewController { return self.childViewControllers.firstOfType() }
    
    private var viewModel: SummaryViewModel!
    private var viewModelLocator: ViewModelLocator!
    
    var disposableBag = DisposeBag()
    
    func inject(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
        self.viewModel = viewModelLocator.getSummaryViewModel()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let summaryPageViewModel = viewModelLocator.getSummaryPageViewModel(forDate: viewModel.date)
        
        titleLabel.text = L10n.dailySummaryTitle
        
        summaryPageViewModel.dateObservable
            .bindTo(self.dateLabel.rx.text)
            .addDisposableTo(disposableBag)
        
        summaryPageViewController.inject(viewModel: summaryPageViewModel, viewModelLocator: viewModelLocator)
        
        self.backButton.rx.tap
            .subscribe(onNext: { self.summaryPageViewController.moveToPreviews() })
            .addDisposableTo(disposeBag)
        
        self.forwardButton.rx.tap
            .subscribe(onNext: { self.summaryPageViewController.moveToNext() })
            .addDisposableTo(disposeBag)
        
        self.summaryPageViewController
            .canMoveForwardObservable
            .subscribe(onNext: { self.forwardButton.isEnabled = $0 })
            .addDisposableTo(self.disposeBag)
        
        self.summaryPageViewController
            .canMoveBackwardObservable
            .subscribe(onNext: { self.backButton.isEnabled = $0 })
            .addDisposableTo(self.disposeBag)
        
        self.closeButton.rx.tap
            .subscribe(onNext: { self.dismiss(animated: true, completion: nil) } )
            .addDisposableTo(self.disposeBag)
    }
}
