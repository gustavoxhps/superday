import UIKit
import RxSwift
import SnapKit

class OnboardingViewController: UIPageViewController
{
    //MARK: Private Properties
    internal lazy var pages : [OnboardingPage] = { return (1...4).map { i in self.page(i) } } ()
    
    private var viewModel : OnboardingViewModel!
    private var presenter : OnboardingPresenter!
    
    @IBOutlet fileprivate var pager: OnboardingPager!
    
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

        dataSource = self
        delegate = self
        view.backgroundColor = UIColor.white
        setViewControllers([pages.first!],
                           direction: .forward,
                           animated: true,
                           completion: nil)
        
        let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [type(of: self)])
        pageControl.pageIndicatorTintColor = Style.Color.green.withAlphaComponent(0.4)
        pageControl.currentPageIndicatorTintColor = Style.Color.green
        pageControl.backgroundColor = UIColor.clear
        
        view.addSubview(pager)
        pager.snp.makeConstraints { [unowned self] make in
            make.left.right.bottom.equalTo(self.view)
            make.height.equalTo(102)
        }
        
        pager.createPageDots(forPageCount: pages.count)
        
        onNew(page: pages[0])
    }
    
    //MARK: Actions
    @IBAction func pagerButtonTouchUpInside()
    {
        goToNextPage(forceNext: false)
    }
    
    //MARK: Methods
    func isCurrent(page: OnboardingPage) -> Bool
    {
        return page == viewControllers?.first
    }

    func goToNextPage(forceNext: Bool)
    {
        let currentlyVisibleIndex = index(of: viewControllers!.first!)!
        let currentPageIndex = forceNext ? lastSeenIndex : currentlyVisibleIndex

        guard let nextPage = pageAt(index: currentPageIndex + 1) else
        {
            
            viewModel.settingsService.setInstallDate(viewModel.timeService.now)
            presenter.showMain()

            return
        }
        
        setViewControllers([nextPage],
                                direction: .forward,
                                animated: true,
                                completion: nil)
        
        onNew(page: nextPage)
    }
    
    //MARK: Private Methods
    
    fileprivate func pageAt(index : Int) -> OnboardingPage?
    {
        lastSeenIndex = max(lastSeenIndex, index)
        return 0..<pages.count ~= index ? pages[index] : nil
    }
    
    fileprivate func index(of viewController: UIViewController) -> Int?
    {
        return pages.index(of: viewController as! OnboardingPage)
    }
    
    private func page(_ id: Int) -> OnboardingPage
    {
        let page = StoryboardScene
                    .Onboarding
                    .storyboard()
                    .instantiateViewController(withIdentifier: "OnboardingScreen\(id)") as! OnboardingPage
        
        page.inject(viewModel: viewModel.pageViewModel(), onboardingPageViewController: self)

        return page
    }
    
    fileprivate func onNew(page: OnboardingPage)
    {
        if let buttonText = page.nextButtonText
        {
            pager.showNextButton(withText: buttonText)
        }
        else
        {
            pager.hideNextButton()
        }
        pager.switchPage(to: index(of: page)!)
    }
}

extension OnboardingViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource
{
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
    {
        let page = pendingViewControllers.first as! OnboardingPage
        
        if page.nextButtonText != nil
        {
            pager.clearButtonText()
        }
        else
        {
            pager.hideNextButton()
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        let page = viewControllers!.first as! OnboardingPage
        onNew(page: page)
    }
    
    
    // MARK: UIPageViewControllerDataSource
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        guard (viewController as! OnboardingPage).allowPagingSwipe else { return nil }
        guard let currentPageIndex = index(of: viewController) else { return nil }
        
        return pageAt(index: currentPageIndex - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        guard (viewController as! OnboardingPage).allowPagingSwipe else { return nil }
        guard let currentPageIndex = index(of: viewController) else { return nil }
        
        return pageAt(index: currentPageIndex + 1)
    }
}
