@testable import teferi
import XCTest
import Nimble

class TopBarViewModelTests : XCTestCase
{
    private var viewModel : TopBarViewModel!
    
    private var timeService : MockTimeService!
    private var feedbackService : MockFeedbackService!
    private var selectedDateService : MockSelectedDateService!
    
    override func setUp()
    {
        self.timeService = MockTimeService()
        self.feedbackService = MockFeedbackService()
        self.selectedDateService = MockSelectedDateService()
        
        self.viewModel =  TopBarViewModel(timeService: self.timeService,
                                          feedbackService: self.feedbackService,
                                          selectedDateService: self.selectedDateService)
    }
    
    func testTheTitlePropertyReturnsSuperdayForTheCurrentDate()
    {
        let today = Date()
        self.selectedDateService.currentlySelectedDate = today
        
        expect(self.viewModel.title).to(equal(L10n.currentDayBarTitle))
    }
    
    func testTheTitlePropertyReturnsSuperyesterdayForYesterday()
    {
        let yesterday = Date().yesterday
        self.selectedDateService.currentlySelectedDate = yesterday
        expect(self.viewModel.title).to(equal(L10n.yesterdayBarTitle))
    }
    
    func testTheTitlePropertyReturnsTheFormattedDayAndMonthForOtherDates()
    {
        let olderDate = Date().add(days: -2)
        self.selectedDateService.currentlySelectedDate = olderDate
        
        let formatter = DateFormatter();
        formatter.timeZone = TimeZone.autoupdatingCurrent;
        formatter.dateFormat = "EEE, dd MMM";
        let expectedText = formatter.string(from: olderDate)
        
        expect(self.viewModel.title).to(equal(expectedText))
    }
    
    func testTheCalendarDayAlwaysReturnsTheCurrentDate()
    {
        self.timeService.mockDate = self.getDate(withDay: 30)
        
        expect(self.viewModel.calendarDay).to(equal("30"))
    }
    
    func testTheCalendarDayAlwaysHasTwoPositions()
    {
        self.timeService.mockDate = self.getDate(withDay: 1)
        
        expect(self.viewModel.calendarDay).to(equal("01"))
    }
    
    private func getDate(withDay day: Int) -> Date
    {
        var dateComponents = DateComponents()
        dateComponents.year = Date().year
        dateComponents.month = 1
        dateComponents.day = day
        
        return Calendar.current.date(from: dateComponents)!
    }
}
