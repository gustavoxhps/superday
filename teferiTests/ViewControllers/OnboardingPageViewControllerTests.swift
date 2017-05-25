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
        
        self.viewModelLocator = MockLocator()
        self.onboardingViewController = OnboardingPresenter.create(with: viewModelLocator)
        
        self.onboardingViewController.loadViewIfNeeded()
        UIApplication.shared.keyWindow!.rootViewController = onboardingViewController
    }
    
    func testTheGoToNextPageMethodNavigatesBetweenPages()
    {
        let page = self.onboardingViewController.viewControllers!.first!
        self.onboardingViewController.goToNextPage(forceNext: false)
        
        expect(self.onboardingViewController.viewControllers!.first).toNot(equal(page))
    }
    
    func testTheFirstPageOftheViewControllerAllowsSwipingRight()
    {
        let page = self.onboardingViewController.pages[0]
        
        let nextPage = self.onboardingViewController
            .pageViewController(self.onboardingViewController, viewControllerBefore: page)
        
        expect(nextPage).to(beNil())
    }
    
    func testTheThirdPageOftheViewControllerDoesNotAllowSwipingRight()
    {
        let page = self.onboardingViewController.pages[2]
        
        let nextPage = self.onboardingViewController
            .pageViewController(self.onboardingViewController, viewControllerBefore: page)
        
        expect(nextPage).to(beNil())
    }
    
    func testTheThirdPageOftheViewControllerDoesNotAllowSwipingLeft()
    {
        let page = self.onboardingViewController.pages[2]
        
        let previousPage = self.onboardingViewController
                               .pageViewController(self.onboardingViewController, viewControllerAfter: page)

        expect(previousPage).to(beNil())
    }
}
