import XCTest
import Nimble
import RxSwift
@testable import teferi

class TimelineViewControllerTests : XCTestCase
{
    private var noon : Date!
    private var locator : MockLocator!
    private var viewModel : TimelineViewModel!
    private var timelineViewController : TimelineViewController!
    
    override func setUp()
    {
        super.setUp()

        self.noon = Date().ignoreTimeComponents().addingTimeInterval(12 * 60 * 60)
        self.locator = MockLocator()
        
        self.locator.timeService.mockDate = self.noon.addingTimeInterval(-120)
        self.locator.timeSlotService.addTimeSlot(withStartTime: self.noon.addingTimeInterval(-120),
                                                 category: .unknown,
                                                 categoryWasSetByUser: true,
                                                 tryUsingLatestLocation: false)
        self.viewModel = self.locator.getTimelineViewModel(forDate: self.noon)
        
        self.timelineViewController = TimelineViewController(viewModel: self.viewModel)
    }
    
    override func tearDown()
    {
        super.tearDown()
        
        self.timelineViewController.viewWillDisappear(false)
        self.timelineViewController = nil
    }
    
    func testScrollingIsDisabledWhenEnteringEditMode()
    {
        self.locator.editStateService.notifyEditingBegan(point: CGPoint(),
                                                         timeSlot: TimeSlot(withStartTime: Date(), category: .unknown, categoryWasSetByUser: false));
        
        let scrollView = self.timelineViewController.tableView!
        
        expect(scrollView.isScrollEnabled).to(beFalse())
    }
    
    func testScrollingIsEnabledWhenExitingEditMode()
    {
        self.locator.editStateService.notifyEditingBegan(point: CGPoint(), timeSlot: TimeSlot(withStartTime: Date(), category: .unknown, categoryWasSetByUser: false));
        self.locator.editStateService.notifyEditingEnded();
        
        let scrollView = self.timelineViewController.tableView!
        
        expect(scrollView.isScrollEnabled).to(beTrue())
    }
    
    func testUIRefreshesAsTimePasses()
    {   
        let indexPath = IndexPath(row: self.viewModel.timelineItems.count - 1, section: 0)
        let cell = self.timelineViewController.tableView(self.timelineViewController.tableView, cellForRowAt: indexPath) as! TimelineCell
        let elapsedTimeLabel = cell.subviews[5] as! UILabel
        let beforeElapsedTimeText = elapsedTimeLabel.text
        
        self.locator.timeService.mockDate = self.noon
        
        DispatchQueue.main.async
        {
            expect(elapsedTimeLabel.text).toNot(equal(beforeElapsedTimeText))
        }
    }
}
