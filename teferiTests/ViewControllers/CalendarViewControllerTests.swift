@testable import teferi
import Foundation
import XCTest
import Nimble

class CalendarViewControllerTests : XCTestCase
{
    private var viewModel : CalendarViewModel!
    private var viewModelLocator : MockLocator!
    
    private var calendarViewController : CalendarViewController!
    
    override func setUp()
    {
        super.setUp()
        
        self.viewModelLocator = MockLocator()
        self.viewModel = self.viewModelLocator.getCalendarViewModel()
        
        self.calendarViewController = StoryboardScene.Main.instantiateCalendar()
        self.calendarViewController.inject(viewModel: self.viewModel)
        self.calendarViewController.loadViewIfNeeded()
    }
    
    override func tearDown()
    {
        super.tearDown()
        
        self.calendarViewController.viewWillDisappear(false)
        self.calendarViewController = nil
    }
    
    func testTheCalendarDisappearsAfterADateIsSelected()
    {
        self.calendarViewController.show()
        
        self.viewModelLocator.selectedDateService.currentlySelectedDate = Date().yesterday
        
        expect(self.calendarViewController.isVisible).to(beFalse())
    }
}
