import Nimble
import RxSwift
import XCTest
@testable import teferi

class OnboardingViewControllerTests : XCTestCase
{
    private var onboardingViewController : OnboardingViewController!
    private var viewModelLocator : ViewModelLocator!
    
    override func setUp()
    {
        super.setUp()
        
        viewModelLocator = MockLocator()
        onboardingViewController = OnboardingPresenter.create(with: viewModelLocator)
        
        onboardingViewController.loadViewIfNeeded()
        UIApplication.shared.keyWindow!.rootViewController = onboardingViewController
    }
    
    func testTheGoToNextPageMethodNavigatesBetweenPages()
    {
        let page = onboardingViewController.viewControllers!.first!
        onboardingViewController.goToNextPage(forceNext: false)
        
        expect(self.onboardingViewController.viewControllers!.first).toNot(equal(page))
    }
    
    func testTheFirstPageOftheViewControllerAllowsSwipingRight()
    {
        let page = onboardingViewController.pages[0]
        
        let nextPage = onboardingViewController
            .pageViewController(onboardingViewController, viewControllerBefore: page)
        
        expect(nextPage).to(beNil())
    }
    
    func testTheThirdPageOftheViewControllerDoesNotAllowSwipingRight()
    {
        let page = onboardingViewController.pages[2]
        
        let nextPage = onboardingViewController
            .pageViewController(onboardingViewController, viewControllerBefore: page)
        
        expect(nextPage).to(beNil())
    }
    
    func testTheThirdPageOftheViewControllerDoesNotAllowSwipingLeft()
    {
        let page = onboardingViewController.pages[2]
        
        let previousPage = onboardingViewController
                               .pageViewController(onboardingViewController, viewControllerAfter: page)

        expect(previousPage).to(beNil())
    }
}
