import XCTest
import Nimble
@testable import teferi

class PagerViewControllerTests : XCTestCase
{
    private var locator : MockLocator!
    private var pagerViewController : PagerViewController!
    
    override func setUp()
    {
        super.setUp()
 
        self.locator = MockLocator()
        self.locator.timeService.mockDate = nil
        
        self.pagerViewController = PagerViewController(coder: NSCoder())!
        self.pagerViewController.inject(viewModelLocator: self.locator)
        
        self.pagerViewController.loadViewIfNeeded()
        UIApplication.shared.keyWindow!.rootViewController = self.pagerViewController
    }
    
    override func tearDown()
    {
        self.pagerViewController.viewWillDisappear(false)
        self.pagerViewController = nil
    }
    
    func testScrollingIsDisabledWhenEnteringEditMode()
    {
        self.locator.editStateService.notifyEditingBegan(point: CGPoint(), timeSlot: self.createEmptyTimeSlot());
        
        let scrollViews =
            self.pagerViewController
                .view
                .subviews
                .flatMap { v in v as? UIScrollView }
        
        expect(scrollViews).to(allPass { !$0!.isScrollEnabled  })
    }
    
    func testScrollingIsEnabledWhenExitingEditMode()
    {
        self.locator.editStateService.notifyEditingBegan(point: CGPoint(), timeSlot: self.createEmptyTimeSlot());
        self.locator.editStateService.notifyEditingEnded();
        
        let scrollViews =
            self.pagerViewController
                .view
                .subviews
                .flatMap { v in v as? UIScrollView }
        
        expect(scrollViews).to(allPass { $0!.isScrollEnabled  })
    }
    
    func testWhenTheAppGetsInactiveTheLastInactiveDateGetsSet()
    {
        self.locator.settingsService.setLastInactiveDate(nil)
        self.locator.appLifecycleService.publish(.movedToBackground)
        
        expect(self.locator.settingsService.lastInactiveDate).toNot(beNil())
    }
    
    func testUiGetsRefreshedWhenTheAppGoesToForegroundTheDayAfterItWentToSleep()
    {
        self.pagerViewController.setViewControllers( [ UIViewController() ], direction: .forward, animated: false, completion: nil)
        
        let date = Date().add(days: -2)
        self.locator.settingsService.setLastInactiveDate(date)
        self.locator.appLifecycleService.publish(.movedToForeground)
        
        expect(self.pagerViewController.viewControllers!.first).to(beAnInstanceOf(TimelineViewController.self))
    }
    
    func testTheLastInactiveDateGetsResetWhenTheAppIsAwakeAndRefreshed()
    {
        let date = Date().add(days: -2)
        self.locator.settingsService.setLastInactiveDate(date)
        self.locator.appLifecycleService.publish(.movedToForeground)
        
        expect(self.locator.settingsService.lastInactiveDate).to(beNil())
    }
    
    func testTheDateObservableNotifiesANewDateWhenTheUserScrollsToADifferentPage()
    {
        var didNotify = false
        
        _ = self.locator
            .selectedDateService
            .currentlySelectedDateObservable
            .subscribe(onNext: { _ in didNotify = true })
        
        self.pagerViewController.pageViewController(self.pagerViewController, didFinishAnimating: true, previousViewControllers: self.pagerViewController.viewControllers!, transitionCompleted: true)
        
        expect(didNotify).to(beTrue())
    }
    
    func testTheViewControllerDoesNotAllowScrollingAfterTheCurrentDate()
    {
        let nextViewController = self.scrollForward()
        
        expect(nextViewController).to(beNil())
    }
    
    func testTheViewControllerDoesNotAllowScrollingBeforeTheInstallDate()
    {
        self.locator.settingsService.setInstallDate(Date())
        
        let previousViewController = self.scrollBack()
        
        expect(previousViewController).to(beNil())
    }
    
    func testTheViewControllerScrollsBackOneDayAtATime()
    {
        self.locator.settingsService.setInstallDate(Date().add(days: -10))
        
        let previousViewController = self.scrollBack()!
        
        expect(previousViewController.date.ignoreTimeComponents()).to(equal(Date().yesterday.ignoreTimeComponents()))
    }
    
    func testTheViewControllerScrollsForwardOneDayAtATime()
    {
        self.locator.settingsService.setInstallDate(Date().add(days: -10))
        
        var previous = self.scrollBack(from: nil)
        previous = self.scrollBack(from: previous)
        
        let nextViewController = self.scrollForward(from: previous)!
        
        expect(nextViewController.date.ignoreTimeComponents()).to(equal(Date().yesterday.ignoreTimeComponents()))
    }
    
    @discardableResult func scrollBack(from viewController: UIViewController? = nil) -> TimelineViewController?
    {
        let targetViewController = viewController ?? self.pagerViewController.viewControllers!.last!
        
        return self.pagerViewController
            .pageViewController(self.pagerViewController, viewControllerBefore: targetViewController) as? TimelineViewController
    }
    
    @discardableResult func scrollForward(from viewController: UIViewController? = nil) -> TimelineViewController?
    {
        let targetViewController = viewController ?? self.pagerViewController.viewControllers!.last!
        
        return self.pagerViewController.pageViewController(self.pagerViewController, viewControllerAfter: targetViewController) as? TimelineViewController
    }
    
    private func createEmptyTimeSlot() -> TimeSlot
    {
        return TimeSlot(withStartTime: Date(),
                        category: .unknown,
                        categoryWasSetByUser: false)
    }
}
