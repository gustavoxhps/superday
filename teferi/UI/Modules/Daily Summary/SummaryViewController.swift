import UIKit
import RxSwift

class SummaryViewController: UIViewController
{

    // MARK: Private Properties
    private var disposeBag : DisposeBag = DisposeBag()
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var backButton: UIButton!
    @IBOutlet weak private var forwardButton: UIButton!
    @IBOutlet weak private var closeButton: UIButton!
    private var summaryPageViewController : SummaryPageViewController { return self.childViewControllers.firstOfType() }
    
    private var viewModel: SummaryViewModel!
    private var viewModelLocator: ViewModelLocator!
    
    private var disposableBag = DisposeBag()
    
    // MARK: Methods
    func inject(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
        viewModel = viewModelLocator.getSummaryViewModel()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let summaryPageViewModel = viewModelLocator.getSummaryPageViewModel(forDate: viewModel.date)
        
        titleLabel.text = L10n.dailySummaryTitle
        
        summaryPageViewModel.dateObservable
            .bindTo(dateLabel.rx.text)
            .addDisposableTo(disposableBag)
        
        summaryPageViewController.inject(viewModel: summaryPageViewModel, viewModelLocator: viewModelLocator)
        
        backButton.rx.tap
            .subscribe(onNext: { [unowned self] in self.summaryPageViewController.moveToPreviews() })
            .addDisposableTo(disposeBag)
        
        forwardButton.rx.tap
            .subscribe(onNext: { [unowned self] in self.summaryPageViewController.moveToNext() })
            .addDisposableTo(disposeBag)
        
        summaryPageViewController
            .canMoveForwardObservable
            .subscribe(onNext: { [unowned self] in self.forwardButton.isEnabled = $0 })
            .addDisposableTo(disposeBag)
        
        summaryPageViewController
            .canMoveBackwardObservable
            .subscribe(onNext: { [unowned self] in self.backButton.isEnabled = $0 })
            .addDisposableTo(disposeBag)
        
        closeButton.rx.tap
            .subscribe(onNext: { [unowned self] in self.dismiss(animated: true, completion: nil) } )
            .addDisposableTo(disposeBag)
    }
}
