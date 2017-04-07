import UIKit
import RxSwift

class PagerViewController : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
    // MARK: Fields
    private let disposeBag = DisposeBag()
    private var viewModel : PagerViewModel!
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
        self.view.backgroundColor = UIColor.white
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
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
        
        self.viewModel.showEditOnLastObservable
            .subscribe(onNext: self.showEditOnLastSlot)
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
    
    private func showEditOnLastSlot()
    {
        let now = Date()
        let viewModel = self.viewModelLocator.getTimelineViewModel(forDate: now)
        let vc = TimelineViewController(viewModel: viewModel)
        
        self.viewModel.currentlySelectedDate = now

        self.setViewControllers([vc],
                                direction: UIPageViewControllerNavigationDirection.forward,
                                animated: false) { _ in
                                    vc.startEditOnLastSlot()
                                }
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
        let viewControllers = [ TimelineViewController(viewModel: self.viewModelLocator.getTimelineViewModel(forDate: date)) ]
        
        self.setViewControllers(viewControllers, direction: moveBackwards ? .reverse : .forward, animated: animated, completion: nil)
    }
    
    // MARK: UIPageViewControllerDelegate implementation
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        guard completed else { return }

        let timelineController = self.viewControllers!.first as! TimelineViewController
        
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
