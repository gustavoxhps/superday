import UIKit
import RxCocoa
import RxSwift

class WeeklySummaryViewController: UIViewController
{
    fileprivate var viewModel : WeeklySummaryViewModel!
    private var presenter : WeeklySummaryPresenter!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var weeklyChartView: ChartView!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var weekLabel: UILabel!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var categoryButtons: ButtonsCollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pieChart: ActivityPieChartView!
    @IBOutlet var emptyStateView: WeeklySummaryEmptyEtateView!
    
    private var disposeBag = DisposeBag()
    
    func inject(presenter:WeeklySummaryPresenter, viewModel: WeeklySummaryViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Color.white
        self.scrollView.addSubview(self.emptyStateView)
        
        closeButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.presenter.dismiss()
            })
            .addDisposableTo(disposeBag)
        
        previousButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.viewModel.nextWeek()
            })
            .addDisposableTo(disposeBag)
        
        nextButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.viewModel.previousWeek()
            })
            .addDisposableTo(disposeBag)
        
        viewModel.weekTitle
            .bindTo(weekLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        // Chart View
        weeklyChartView.datasource = viewModel
        weeklyChartView.delegate = self

        viewModel.firstDayIndex
            .subscribe(onNext:weeklyChartView.setWeekStart)
            .addDisposableTo(disposeBag)
        
        // Category Buttons
        categoryButtons.toggleCategoryObservable
            .subscribe(onNext:viewModel.toggleCategory)
            .addDisposableTo(disposeBag)
        
        categoryButtons.categories = viewModel.topCategories
            .do(onNext: { [unowned self] _ in
                self.weeklyChartView.refresh()
            })
        
        //Pie chart
        viewModel
            .weekActivities
            .map { activityWithPercentage in
                return activityWithPercentage.map { $0.0 }
            }
            .subscribe(onNext:self.pieChart.setActivities)
            .addDisposableTo(disposeBag)
        
        //Table view
        tableView.rowHeight = 48
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        viewModel.weekActivities
            .do(onNext: { [unowned self] activities in
                self.tableViewHeightConstraint.constant = CGFloat(activities.count * 48)
                self.view.setNeedsLayout()
            })
            .map { [unowned self] activities in
                return activities.sorted(by: self.areInIncreasingOrder)
            }
            .bindTo(tableView.rx.items(cellIdentifier: WeeklySummaryCategoryTableViewCell.identifier, cellType: WeeklySummaryCategoryTableViewCell.self)) {
                _, model, cell in
                cell.activityWithPercentage = model
            }
            .addDisposableTo(disposeBag)
        
        //Empty state
        viewModel.weekActivities
            .subscribe(onNext: { activityWithPercentage in
                self.emptyStateView.isHidden = !activityWithPercentage.isEmpty
            })
            .addDisposableTo(disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        scrollView.flashScrollIndicators()
    }
    
    private func areInIncreasingOrder(a1: ActivityWithPercentage, a2: ActivityWithPercentage) -> Bool
    {
        return a1.1 > a2.1
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        self.emptyStateView.frame = self.weeklyChartView.frame
    }
}


extension WeeklySummaryViewController: ChartViewDelegate
{
    func pageChange(index: Int)
    {
        viewModel.setFirstDay(index: index)
    }
}
