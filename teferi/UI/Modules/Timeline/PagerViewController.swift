import UIKit
import RxSwift

class PagerViewController : UIPageViewController
{
    // MARK: Private Properties
    fileprivate var viewModel: PagerViewModel!
    private var presenter: PagerPresenter!
    
    private let disposeBag = DisposeBag()
    
    private var viewControllersDictionary = [Date : UIViewController]()
    
    fileprivate var headerView : DailySummaryBarView = DailySummaryBarView()
    
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
    
    func inject(presenter: PagerPresenter, viewModel: PagerViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel        
        
        createBindings()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        delegate = self
        dataSource = self
        view.backgroundColor = UIColor.white
        
        view.addSubview(headerView)
        headerView.createConstraints()
        headerView.addGestureRecognizer(ClosureGestureRecognizer(withClosure: { [unowned self] in
            self.presenter.showDailySummary()
        }))
        
        headerView.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        headerView.layer.shadowOffset = CGSize(width: 0, height: 0)
        headerView.layer.shadowOpacity = 0.0
        headerView.layer.shadowRadius = 4.0
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        setCurrentViewController(forDate: viewModel.currentlySelectedDate, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        viewControllersDictionary = [Date : UIViewController]()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        headerView.layer.shadowPath = UIBezierPath(rect: headerView.bounds).cgPath
    }
    
    // MARK: Private Methods
    
    private func createBindings()
    {
        viewModel.dateObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: onDateChanged)
            .addDisposableTo(disposeBag)
        
        viewModel.isEditingObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: onEditChanged)
            .addDisposableTo(disposeBag)
        
        viewModel.showEditOnLastObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: showToday)
            .addDisposableTo(disposeBag)
        
        viewModel.newDayObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: newDay)
            .addDisposableTo(disposeBag)
                
        viewModel.activitiesObservable
            .drive(onNext: headerView.setActivities)
            .addDisposableTo(disposeBag)
    }

    private func onEditChanged(_ isEditing: Bool)
    {
        view.subviews
            .flatMap { v in v as? UIScrollView }
            .forEach { scrollView in scrollView.isScrollEnabled = !isEditing }
    }
    
    private func newDay()
    {
        viewControllersDictionary = [Date : UIViewController]()
        showToday()
    }
    
    private func showToday()
    {
        viewModel.currentlySelectedDate = viewModel.currentDate
        setCurrentViewController(forDate: viewModel.currentDate, animated: false)
    }
    
    private func onDateChanged(_ dateChange: DateChange)
    {
        setCurrentViewController(forDate: dateChange.newDate,
                                      animated: true,
                                      moveBackwards: dateChange.newDate < dateChange.oldDate)
    }
    
    private func setCurrentViewController(forDate date: Date, animated: Bool, moveBackwards: Bool = false)
    {
        let viewControllers = [viewControllerForDate(date: date)]
        setViewControllers(viewControllers, direction: moveBackwards ? .reverse : .forward, animated: animated, completion: nil)
    }
    
    fileprivate func viewControllerForDate(date: Date) -> UIViewController
    {
        guard let vc = viewControllersDictionary[date.ignoreTimeComponents()] else
        {
            let newVc =  presenter.createTimeline(forDate: date)
            viewControllersDictionary[date.ignoreTimeComponents()] = newVc
            newVc.delegate = self
            return newVc
        }
        
        return vc
    }
}

extension PagerViewController : UIPageViewControllerDelegate, UIPageViewControllerDataSource
{
    // MARK: UIPageViewControllerDelegate implementation
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        guard completed else { return }
        
        let timelineController = viewControllers!.first as! TimelineViewController
        
        viewModel.currentlySelectedDate = timelineController.date
    }
    
    // MARK: UIPageViewControllerDataSource implementation
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        let timelineController = viewController as! TimelineViewController
        let nextDate = timelineController.date.yesterday
        
        guard viewModel.canScroll(toDate: nextDate) else { return nil }
        
        return viewControllerForDate(date: nextDate)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        let timelineController = viewController as! TimelineViewController
        let nextDate = timelineController.date.tomorrow
        
        guard viewModel.canScroll(toDate: nextDate) else { return nil }
        
        return viewControllerForDate(date: nextDate)
    }
}

extension PagerViewController: TimelineDelegate
{
    func resizeHeader(size: CGFloat)
    {
        self.headerView.resize(by: size)
    }
    
    func chageShadow(opacity: Float)
    {
        self.headerView.layer.shadowOpacity = opacity
    }
}
