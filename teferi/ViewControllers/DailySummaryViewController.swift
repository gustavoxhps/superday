import UIKit

class DailySummaryViewController: UIViewController, UITableViewDataSource
{
    @IBOutlet weak var chartView: DailySummaryPieChartActivity!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateView: EmptyDailySummaryView!
    
    private var viewModel: DailySummaryViewModel!
    private let cellIdentifier = "dailySummaryCell"
    
    var date : Date { return self.viewModel.date }

    // MARK: Methods
    func inject(viewModel: DailySummaryViewModel)
    {
        self.viewModel = viewModel
    }
    
    // MARK: - Liffecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        chartView.dailyActivities = viewModel.activities
        
        emptyStateView.isHidden = viewModel.activities.count > 0
        
        tableView.rowHeight = 24
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return viewModel.activities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! DailySummaryTableViewCell
        cell.setup(with: viewModel.activities[indexPath.row], totalDuration: viewModel.activities.totalDurations)
        
        return cell
    }
}
