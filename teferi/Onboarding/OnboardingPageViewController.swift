import UIKit
import RxSwift
import SnapKit

class OnboardingPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
    //MARK: Fields
    internal lazy var pages : [OnboardingPage] = { return (1...4).map { i in self.page("\(i)") } } ()
    
    private var launchAnim : LaunchAnimationView!
    
    @IBOutlet var pager: OnboardingPager!
    
    private var lastSeenIndex = 0
    private var timeService : TimeService!
    private var timeSlotService : TimeSlotService!
    private var settingsService : SettingsService!
    private var appStateService : AppStateService!
    private var mainViewController : MainViewController!
    private var notificationService : NotificationService!
    
    //MARK: ViewController lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.dataSource = self
        self.delegate = self
        self.view.backgroundColor = Color.white
        self.setViewControllers([pages.first!],
                           direction: .forward,
                           animated: true,
                           completion: nil)
        
        let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [type(of: self)])
        pageControl.pageIndicatorTintColor = Color.green.withAlphaComponent(0.4)
        pageControl.currentPageIndicatorTintColor = Color.green
        pageControl.backgroundColor = UIColor.clear
        
        self.view.addSubview(self.pager)
        self.pager.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self.view)
            make.height.equalTo(102)
        }
        
        self.pager.createPageDots(forPageCount: self.pages.count)
        
        self.launchAnim = LaunchAnimationView(frame: self.view.bounds)
        self.view.addSubview(self.launchAnim)
        self.startLaunchAnimation()
        self.onNew(page: self.pages[0])
    }
    
    //MARK: Actions
    @IBAction func pagerButtonTouchUpInside()
    {
        self.goToNextPage(forceNext: false)
    }
    
    //MARK: Methods
    func inject(_ timeService: TimeService,
                _ timeSlotService: TimeSlotService,
                _ settingsService: SettingsService,
                _ appStateService: AppStateService,
                _ mainViewController: MainViewController,
                _ notificationService: NotificationService) -> OnboardingPageViewController
    {
        self.timeService = timeService
        self.appStateService = appStateService
        self.timeSlotService = timeSlotService
        self.settingsService = settingsService
        self.mainViewController = mainViewController
        self.notificationService = notificationService
        return self
    }
    
    func isCurrent(page: OnboardingPage) -> Bool
    {
        return page == self.viewControllers?.first
    }
    
    private func startLaunchAnimation()
    {
        //Small delay to give launch screen time to fade away
        Timer.schedule(withDelay: 0.1) { _ in
            self.launchAnim.animate(onCompleted:
            {
                self.launchAnim.removeFromSuperview()
                self.launchAnim = nil
            })
        }
    }
    
    func goToNextPage(forceNext: Bool)
    {
        let currentlyVisibleIndex = self.index(of: self.viewControllers!.first!)!
        let currentPageIndex = forceNext ? self.lastSeenIndex : currentlyVisibleIndex
        guard let nextPage = self.pageAt(index: currentPageIndex + 1) else
        {
            self.settingsService.setInstallDate(self.timeService.now)
         
            DispatchQueue.main.async
            {
                self.mainViewController.modalTransitionStyle = .crossDissolve
                self.present(self.mainViewController, animated: true)
            }

            return
        }
        
        self.setViewControllers([nextPage],
                                direction: .forward,
                                animated: true,
                                completion: nil)
        
        self.onNew(page: nextPage)
    }
    
    private func pageAt(index : Int) -> OnboardingPage?
    {
        self.lastSeenIndex = max(self.lastSeenIndex, index)
        return 0..<self.pages.count ~= index ? self.pages[index] : nil
    }
    
    private func index(of viewController: UIViewController) -> Int?
    {
        return self.pages.index(of: viewController as! OnboardingPage)
    }
    
    private func page(_ id: String) -> OnboardingPage
    {
        let page = StoryboardScene
                    .Onboarding
                    .storyboard()
                    .instantiateViewController(withIdentifier: "OnboardingScreen\(id)") as! OnboardingPage
        
        page.inject(self.timeService,
                    self.timeSlotService,
                    self.settingsService,
                    self.appStateService,
                    self.notificationService, self)
        
        return page
    }
    
    private func onNew(page: OnboardingPage)
    {
        if let buttonText = page.nextButtonText
        {
            self.pager.showNextButton(withText: buttonText)
        }
        else
        {
            self.pager.hideNextButton()
        }
        self.pager.switchPage(to: self.index(of: page)!)
    }
    
    // MARK: UIPageViewControllerDelegate
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
    {
        let page = pendingViewControllers.first as! OnboardingPage
        
        if page.nextButtonText != nil
        {
            self.pager.clearButtonText()
        }
        else
        {
            self.pager.hideNextButton()
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        let page = self.viewControllers!.first as! OnboardingPage
        self.onNew(page: page)
    }
    
    
    // MARK: UIPageViewControllerDataSource
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        guard (viewController as! OnboardingPage).allowPagingSwipe else { return nil }
        guard let currentPageIndex = self.index(of: viewController) else { return nil }
        
        return self.pageAt(index: currentPageIndex - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        guard (viewController as! OnboardingPage).allowPagingSwipe else { return nil }
        guard let currentPageIndex = self.index(of: viewController) else { return nil }
        
        return self.pageAt(index: currentPageIndex + 1)
    }
}
