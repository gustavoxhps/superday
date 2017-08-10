import XCTest
import Nimble
import RxSwift
import RxTest
@testable import teferi

class CalendarViewModelTests: XCTestCase
{
    private var viewModel : CalendarViewModel!
    private var disposeBag : DisposeBag = DisposeBag()
    
    private var timeService : MockTimeService!
    private var settingsService : MockSettingsService!
    private var timeSlotService : SimpleMockTimeSlotService!
    private var selectedDateService : MockSelectedDateService!
    
    private var scheduler: TestScheduler!
    
    override func setUp()
    {
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock:0)

        timeService = MockTimeService()
        settingsService = MockSettingsService()
        selectedDateService = MockSelectedDateService()
        timeSlotService = SimpleMockTimeSlotService()
        
        viewModel = CalendarViewModel(timeService: timeService,
                                      settingsService: settingsService,
                                      timeSlotService: timeSlotService,
                                      selectedDateService: selectedDateService)
    }
    
    func testSelectedDateForwardsToService()
    {
        let observer:TestableObserver<Date> = scheduler.createObserver(Date.self)
        selectedDateService.currentlySelectedDateObservable
            .skip(1)
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        let dates = [Date().addingTimeInterval(2*24*60*60), Date().addingTimeInterval(3*24*60*60)]
        viewModel.selectedDate = dates[0]
        viewModel.selectedDate = dates[1]

        expect(observer.events.count).to(equal(2))
        expect(observer.values).to(equal(dates))
    }
    
    func testCurrentlyVisibleCalendarDateForwardsEventsToObservableOnlyWhenMonthChanges()
    {
        let observer:TestableObserver<Date> = scheduler.createObserver(Date.self)
        viewModel.currentVisibleCalendarDateObservable
            .skip(1)
            .subscribe(observer)
            .addDisposableTo(disposeBag)
        
        let dates = [Date().addingTimeInterval(2*24*60*60), Date().addingTimeInterval(35*24*60*60)]
        viewModel.setCurrentVisibleMonth(date: dates[0])
        viewModel.setCurrentVisibleMonth(date: dates[1])
        
        expect(observer.events.count).to(equal(1))
        expect(observer.values.first!).to(equal(dates[1].firstDateOfMonth))
    }
    
    func testMaxValidDateReturnsCurrentDateAlways()
    {
        let now = Date()
        
        timeService.mockDate = now
        expect(self.viewModel.maxValidDate).to(equal(now))
        
        timeService.mockDate = now.addingTimeInterval(3*24*60*60)
        expect(self.viewModel.maxValidDate).to(equal(now.addingTimeInterval(3*24*60*60)))
    }
    
    func testCantScrollToDatePreviousToInstallDate()
    {
        let installDate = Date().addingTimeInterval(-3*24*60*60)
        let toDate = installDate.addingTimeInterval(-1*24*60*60)
        
        settingsService.setInstallDate(installDate)
        
        expect(self.viewModel.canScroll(toDate: toDate)).to(beFalse())
    }
    
    func testCantScrollToDateLaterThanCurrentDate()
    {
        let currentDate = Date()
        let toDate = currentDate.addingTimeInterval(3*24*60*60)
        
        timeService.mockDate = currentDate
        
        expect(self.viewModel.canScroll(toDate: toDate)).to(beFalse())
    }
    
    func testCanScrollToDateBetweenInstallAndCurrentDates()
    {
        let currentDate = Date()
        let installDate = Date().addingTimeInterval(-4*24*60*60)
        let toDate = currentDate.addingTimeInterval(-2*24*60*60)
        
        timeService.mockDate = currentDate
        settingsService.setInstallDate(installDate)
        
        expect(self.viewModel.canScroll(toDate: toDate)).to(beTrue())
    }
    
    func testGetActivitiesReturnsNilForInvalidDate()
    {
        let currentDate = Date()
        let dateRequested = currentDate.addingTimeInterval(3*24*60*60)
        
        timeService.mockDate = currentDate
        
        timeSlotService.timeSlotsToReturn = [
            TimeSlot(withStartTime: Date(), category: .food, categoryWasSetByUser: false),
            TimeSlot(withStartTime: Date(), category: .work, categoryWasSetByUser: false),
            TimeSlot(withStartTime: Date(), category: .leisure, categoryWasSetByUser: false)
        ]
        
        let activities = viewModel.getActivities(forDate: dateRequested)
        
        expect(activities).to(beNil())
    }
    
    func testGetActivitiesAsksTimeSlotsForDateAndSortsThemByCategory()
    {
        let currentDate = Date()
        let installDate = Date().addingTimeInterval(-4*24*60*60)
        let dateRequested = currentDate.addingTimeInterval(-2*24*60*60)
        
        timeService.mockDate = currentDate
        settingsService.setInstallDate(installDate)

        timeSlotService.timeSlotsToReturn = [
            TimeSlot(withStartTime: Date(), category: .food, categoryWasSetByUser: false),
            TimeSlot(withStartTime: Date(), category: .work, categoryWasSetByUser: false),
            TimeSlot(withStartTime: Date(), category: .leisure, categoryWasSetByUser: false)
        ]
        
        let activities = viewModel.getActivities(forDate: dateRequested)
        
        expect(self.timeSlotService.dateAsked).to(equal(dateRequested))
        expect(activities!.count).to(equal(3))
        expect(activities!.map{ $0.category }).to(equal([.leisure, .food, .work]))
    }
}
