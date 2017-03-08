import UIKit
import RxSwift

class PagerViewController : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
    // MARK: Fields
    private let disposeBag = DisposeBag()
    private var viewModel : PagerViewModel!
    private var viewModelLocator : ViewModelLocator!
    private var currentDateViewController : TimelineViewController!
    
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
    
    // MARK: UIViewController lifecycle
    
    func inject(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
        self.viewModel = viewModelLocator.getPagerViewModel()
        
        self.createBindings()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.delegate = self
        self.dataSource = self
        self.view.backgroundColor = Color.white
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        self.setCurrentViewController(forDate: self.viewModel.currentlySelectedDate, animated: false)
    }
    
    private func createBindings()
    {
        self.viewModel
            .dateObservable
            .subscribe(onNext: self.onDateChanged)
            .addDisposableTo(self.disposeBag)
        
        self.viewModel
            .isEditingObservable
            .subscribe(onNext: onEditChanged)
            .addDisposableTo(self.disposeBag)
        
        self.viewModel
            .refreshObservable
            .subscribe(onNext: self.onRefreshView)
            .addDisposableTo(self.disposeBag)
    }
    
    // MARK: Methods
    private func onEditChanged(_ isEditing: Bool)
    {
        self.view
            .subviews
            .flatMap { v in v as? UIScrollView }
            .forEach { scrollView in scrollView.isScrollEnabled = !isEditing }
    }
    
    private func onRefreshView()
    {
        self.initCurrentDateViewController()
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
    
    private func initCurrentDateViewController()
    {
        let viewModel = self.viewModelLocator.getTimelineViewModel(forDate: Date())
        self.currentDateViewController = TimelineViewController(viewModel: viewModel)
        
        self.setViewControllers(
            [ currentDateViewController ],
            direction: .forward,
            animated: false,
            completion: nil)
    }
    
    private func setCurrentViewController(forDate date: Date, animated: Bool, moveBackwards: Bool = false)
    {
        let viewControllers = [ TimelineViewController(viewModel: self.viewModelLocator.getTimelineViewModel(forDate: date)) ]
        
        self.setViewControllers(viewControllers, direction: moveBackwards ? .reverse : .forward, animated: animated, completion: nil)
    }
    
    // MARK: UIPageViewControllerDelegate implementation
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        guard completed else { return }

        let timelineController = self.viewControllers!.first as! TimelineViewController
        
        if timelineController.date.ignoreTimeComponents() == self.viewModel.currentDate.ignoreTimeComponents()
        {
            self.currentDateViewController = timelineController
        }
        
        self.viewModel.currentlySelectedDate = timelineController.date
    }
    
    // MARK: UIPageViewControllerDataSource implementation
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        let timelineController = viewController as! TimelineViewController
        let nextDate = timelineController.date.yesterday
        
        guard self.viewModel.canScroll(toDate: nextDate) else { return nil }
        
        let viewModel = self.viewModelLocator.getTimelineViewModel(forDate: nextDate)
        return TimelineViewController(viewModel: viewModel)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        let timelineController = viewController as! TimelineViewController
        let nextDate = timelineController.date.tomorrow
        
        guard self.viewModel.canScroll(toDate: nextDate) else { return nil }
        
        let viewModel = self.viewModelLocator.getTimelineViewModel(forDate: nextDate)
        return TimelineViewController(viewModel: viewModel)
    }
}
