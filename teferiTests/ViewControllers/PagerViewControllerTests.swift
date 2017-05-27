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
 
        locator = MockLocator()
        locator.timeSlotService = PagerMockTimeSlotService(timeService: locator.timeService, locationService: locator.locationService)
        locator.timeService.mockDate = nil
        
        pagerViewController = PagerViewController(coder: NSCoder())!
        pagerViewController.inject(viewModelLocator: locator)
        
        pagerViewController.loadViewIfNeeded()
        UIApplication.shared.keyWindow!.rootViewController = pagerViewController
    }
    
    override func tearDown()
    {
        pagerViewController.viewWillDisappear(false)
        pagerViewController = nil
    }
    
    func testScrollingIsDisabledWhenEnteringEditMode()
    {
        locator.editStateService.notifyEditingBegan(point: CGPoint(), timeSlot: createEmptyTimeSlot());
        
        let scrollViews =
            pagerViewController
                .view
                .subviews
                .flatMap { v in v as? UIScrollView }
        
        expect(scrollViews).to(allPass { !$0!.isScrollEnabled  })
    }
    
    func testScrollingIsEnabledWhenExitingEditMode()
    {
        locator.editStateService.notifyEditingBegan(point: CGPoint(), timeSlot: createEmptyTimeSlot());
        locator.editStateService.notifyEditingEnded();
        
        let scrollViews =
            pagerViewController
                .view
                .subviews
                .flatMap { v in v as? UIScrollView }
        
        expect(scrollViews).to(allPass { $0!.isScrollEnabled  })
    }
    
    func testTheDateObservableNotifiesANewDateWhenTheUserScrollsToADifferentPage()
    {
        var didNotify = false
        
        _ = locator
            .selectedDateService
            .currentlySelectedDateObservable
            .subscribe(onNext: { _ in didNotify = true })
        
        pagerViewController.pageViewController(pagerViewController, didFinishAnimating: true, previousViewControllers: pagerViewController.viewControllers!, transitionCompleted: true)
        
        expect(didNotify).to(beTrue())
    }
    
    func testTheViewControllerDoesNotAllowScrollingAfterTheCurrentDate()
    {
        let nextViewController = scrollForward()
        
        expect(nextViewController).to(beNil())
    }
    
    func testTheViewControllerDoesNotAllowScrollingBeforeTheInstallDate()
    {
        locator.settingsService.setInstallDate(Date())
        
        let previousViewController = scrollBack()
        
        expect(previousViewController).to(beNil())
    }
    
    func testTheViewControllerScrollsBackOneDayAtATime()
    {
        locator.settingsService.setInstallDate(Date().add(days: -10))
        
        let previousViewController = scrollBack()!
        
        expect(previousViewController.date.ignoreTimeComponents()).to(equal(Date().yesterday.ignoreTimeComponents()))
    }
    
    func testTheViewControllerScrollsForwardOneDayAtATime()
    {
        locator.settingsService.setInstallDate(Date().add(days: -10))
        
        var previous = scrollBack(from: nil)
        previous = scrollBack(from: previous)
        
        let nextViewController = scrollForward(from: previous)!
        
        expect(nextViewController.date.ignoreTimeComponents()).to(equal(Date().yesterday.ignoreTimeComponents()))
    }
    
    @discardableResult func scrollBack(from viewController: UIViewController? = nil) -> TimelineViewController?
    {
        let targetViewController = viewController ?? pagerViewController.viewControllers!.last!
        
        return pagerViewController
            .pageViewController(pagerViewController, viewControllerBefore: targetViewController) as? TimelineViewController
    }
    
    @discardableResult func scrollForward(from viewController: UIViewController? = nil) -> TimelineViewController?
    {
        let targetViewController = viewController ?? pagerViewController.viewControllers!.last!
        
        return pagerViewController.pageViewController(pagerViewController, viewControllerAfter: targetViewController) as? TimelineViewController
    }
    
    private func createEmptyTimeSlot() -> TimeSlot
    {
        return TimeSlot(withStartTime: Date(),
                        category: .unknown,
                        categoryWasSetByUser: false)
    }
}
