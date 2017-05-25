import UIKit
import RxSwift
import SnapKit

class OnboardingViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
    private var viewModel : OnboardingViewModel!
    private var presenter : OnboardingPresenter!
    
    //MARK: Fields
    internal lazy var pages : [OnboardingPage] = { return (1...4).map { i in self.page("\(i)") } } ()
    
    @IBOutlet var pager: OnboardingPager!
    
    private var lastSeenIndex = 0
    
    func inject(presenter: OnboardingPresenter, viewModel:OnboardingViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
    }
    
    //MARK: ViewController lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.dataSource = self
        self.delegate = self
        self.view.backgroundColor = UIColor.white
        self.setViewControllers([pages.first!],
                           direction: .forward,
                           animated: true,
                           completion: nil)
        
        let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [type(of: self)])
        pageControl.pageIndicatorTintColor = Style.Color.green.withAlphaComponent(0.4)
        pageControl.currentPageIndicatorTintColor = Style.Color.green
        pageControl.backgroundColor = UIColor.clear
        
        self.view.addSubview(self.pager)
        self.pager.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self.view)
            make.height.equalTo(102)
        }
        
        self.pager.createPageDots(forPageCount: self.pages.count)
        
        self.onNew(page: self.pages[0])
    }
    
    //MARK: Actions
    @IBAction func pagerButtonTouchUpInside()
    {
        self.goToNextPage(forceNext: false)
    }
    
    //MARK: Methods
    func isCurrent(page: OnboardingPage) -> Bool
    {
        return page == self.viewControllers?.first
    }

    func goToNextPage(forceNext: Bool)
    {
        let currentlyVisibleIndex = self.index(of: self.viewControllers!.first!)!
        let currentPageIndex = forceNext ? self.lastSeenIndex : currentlyVisibleIndex

        guard let nextPage = self.pageAt(index: currentPageIndex + 1) else
        {
            
            self.viewModel.settingsService.setInstallDate(self.viewModel.timeService.now)
            self.presenter.showMain()

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
        
        page.inject(self.viewModel.timeService,
                    self.viewModel.timeSlotService,
                    self.viewModel.settingsService,
                    self.viewModel.appLifecycleService,
                    self.viewModel.notificationService, self)
        
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
