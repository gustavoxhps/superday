import UIKit

class DailySummaryViewController: UIViewController, UITableViewDataSource
{
    // MARK: Public Properties
    var date : Date { return self.viewModel.date }
    
    // MARK: Private Properties
    @IBOutlet weak private var chartView: DailySummaryPieChartActivity!
    @IBOutlet weak private var tableView: UITableView!
    
    private var viewModel: DailySummaryViewModel!
    private let cellIdentifier = "dailySummaryCell"

    // MARK: Public Methods
    func inject(viewModel: DailySummaryViewModel)
    {
        self.viewModel = viewModel
    }
    
    // MARK: - Liffecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        chartView.dailyActivities = viewModel.activities
        
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
