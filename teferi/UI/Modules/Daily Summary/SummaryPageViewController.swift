import UIKit
import RxSwift

class SummaryPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
    // MARK: Public Properties
    var canMoveForwardObservable : Observable<Bool>!
    var canMoveBackwardObservable : Observable<Bool>!
    
    // MARK: Private Properties
    private var viewModel : SummaryPageViewModel!
    private var viewModelLocator : ViewModelLocator!
    
    // MARK: Initializers
    override init(transitionStyle style: UIPageViewControllerTransitionStyle, navigationOrientation: UIPageViewControllerNavigationOrientation, options: [String : Any]?)
    {
        super.init(transitionStyle: .scroll,
                   navigationOrientation: .horizontal,
                   options: options)
    }
    
    required convenience init?(coder: NSCoder)
    {
        self.init(transitionStyle: .scroll,
                  navigationOrientation: .horizontal,
                  options: nil)
    }
    
    // MARK: - Methods
    func inject(viewModel : SummaryPageViewModel,
                viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
        self.viewModel = viewModel
        
        canMoveForwardObservable = viewModel.canMoveForwardObservable
        canMoveBackwardObservable = viewModel.canMoveBackwardObservable
    }
    
    func moveToNext()
    {
        setCurrentViewController(forDate: viewModel.currentlySelectedDate.add(days: 1), animated: true)
    }
    
    func moveToPreviews()
    {
        setCurrentViewController(forDate: viewModel.currentlySelectedDate.add(days: -1), animated: true, moveBackwards: true)
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        delegate = self
        dataSource = self
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 10
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        setCurrentViewController(forDate: viewModel.currentlySelectedDate, animated: false)
    }
    
    // MARK: UIPageViewControllerDelegate implementation
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        guard completed else { return }
        
        let dailySummaryViewController = viewControllers!.first as! DailySummaryViewController
        
        viewModel.currentlySelectedDate = dailySummaryViewController.date
    }
    
    // MARK: UIPageViewControllerDataSource implementation
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        let dailySummaryViewController = viewController as! DailySummaryViewController
        let nextDate = dailySummaryViewController.date.yesterday
        
        guard viewModel.canScroll(toDate: nextDate) else { return nil }
        
        return newDailySummaryViewController(forDate: nextDate)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        let dailySummaryViewController = viewController as! DailySummaryViewController
        let nextDate = dailySummaryViewController.date.tomorrow
        
        guard viewModel.canScroll(toDate: nextDate) else { return nil }
        
        return newDailySummaryViewController(forDate: nextDate)
    }
    
    // MARK: - Helper
    private func newDailySummaryViewController(forDate date: Date) -> DailySummaryViewController
    {
        let dailySummarryViewController = StoryboardScene.DailySummary.instantiateDailySummary()
        dailySummarryViewController.inject(viewModel: viewModelLocator.getDailySummaryViewModel(forDate: date))
        return dailySummarryViewController
    }
    
    private func onDateChanged(_ dateChange: DateChange)
    {
        DispatchQueue.main.async
            {
                self.setCurrentViewController(forDate: dateChange.newDate,
                                              animated: true,
                                              moveBackwards: dateChange.newDate < dateChange.oldDate)
        }
    }
    
    private func setCurrentViewController(forDate date: Date, animated: Bool, moveBackwards: Bool = false)
    {
        let viewControllers = [ newDailySummaryViewController(forDate: date) ]
        
        setViewControllers(viewControllers, direction: moveBackwards ? .reverse : .forward, animated: animated, completion: nil)
        
        viewModel.currentlySelectedDate = date
    }

}
