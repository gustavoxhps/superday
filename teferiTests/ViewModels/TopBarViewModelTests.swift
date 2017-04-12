@testable import teferi
import XCTest
import Nimble
import RxTest
import RxSwift

class TopBarViewModelTests : XCTestCase
{
    private var viewModel : TopBarViewModel!
    
    private var timeService : MockTimeService!
    private var feedbackService : MockFeedbackService!
    private var selectedDateService : MockSelectedDateService!
    private var appLifecycleService : MockAppLifecycleService!
    
    private var disposeBag : DisposeBag!
    
    private var scheduler : TestScheduler!
    private var dateLabelObserver: TestableObserver<String>!

    
    override func setUp()
    {
        self.timeService = MockTimeService()
        self.feedbackService = MockFeedbackService()
        self.selectedDateService = MockSelectedDateService()
        self.appLifecycleService = MockAppLifecycleService()
        
        disposeBag = DisposeBag()
        
        self.timeService.mockDate = getDate(withDay: 13)
        
        self.viewModel =  TopBarViewModel(timeService: self.timeService,
                                          feedbackService: self.feedbackService,
                                          selectedDateService: self.selectedDateService,
                                          appLifecycleService: self.appLifecycleService)
        
        scheduler = TestScheduler(initialClock:0)
        dateLabelObserver = scheduler.createObserver(String.self)
        
        viewModel.calendarDay
            .subscribe(dateLabelObserver)
            .addDisposableTo(disposeBag)
    }
    
    func testTheTitlePropertyReturnsSuperdayForTheCurrentDate()
    {
        let today = self.timeService.mockDate!
        self.selectedDateService.currentlySelectedDate = today
        
        expect(self.viewModel.title).to(equal(L10n.currentDayBarTitle))
    }
    
    func testTheTitlePropertyReturnsSuperyesterdayForYesterday()
    {
        let yesterday = self.timeService.mockDate!.yesterday
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
        let dateText = dateLabelObserver.events.last!.value.element!

        expect(dateText).to(equal("13"))
    }
    
    func testTheCalendarDayAlwaysHasTwoPositions()
    {
        self.appLifecycleService.publish(.movedToBackground)
        self.timeService.mockDate = self.getDate(withDay: 1)
        self.appLifecycleService.publish(.movedToForeground(fromNotification: false))
        
        let dateText = dateLabelObserver.events.last!.value.element!
        
        expect(dateText).to(equal("01"))
    }
    
    func testDateLabelChangesIfDateChangesWhileOnBackground()
    {
        self.appLifecycleService.publish(.movedToBackground)
        self.timeService.mockDate = self.getDate(withDay: 14)
        self.appLifecycleService.publish(.movedToForeground(fromNotification: false))
        
        let dateText = dateLabelObserver.events.last!.value.element!

        expect(dateText).to(equal("14"))
    }
    
    func testTheTitleChangesWhenTheDateChanges()
    {
        let today = self.timeService.mockDate!
        self.selectedDateService.currentlySelectedDate = today

        self.appLifecycleService.publish(.movedToBackground)
        self.timeService.mockDate = today.add(days: 1)
        self.appLifecycleService.publish(.movedToForeground(fromNotification: false))
        
        expect(self.viewModel.title).to(equal(L10n.yesterdayBarTitle))
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
