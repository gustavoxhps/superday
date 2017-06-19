import Foundation
import RxSwift

protocol WeeklySummaryInput
{
    func nextWeek()
    func previousWeek()
    func setFirstDay(index: Int)
    func toggleCategory(category: Category)
}

typealias ActivityWithPercentage = (Activity, Double)

protocol WeeklySummaryOutput: ChartViewDatasource
{
    var weekTitle: Observable<String>! { get }
    var weekActivities: Observable<[ActivityWithPercentage]>! { get }
    var firstDayIndex: Observable<Int> { get }
    var topCategories: Observable<[CategoryButtonModel]> { get }
}

class WeeklySummaryViewModel: WeeklySummaryInput, WeeklySummaryOutput
{
    fileprivate let timeService : TimeService
    fileprivate let timeSlotService : TimeSlotService
    fileprivate let settingsService : SettingsService
    
    var weekTitle: Observable<String>!
    var weekActivities: Observable<[ActivityWithPercentage]>!
    var firstDayIndex: Observable<Int>
    {
        return weekStart.asObservable()
    }
    var topCategories: Observable<[CategoryButtonModel]>
    {
        return topCategoriesVariable.asObservable()
    }
    
    fileprivate var topCategoriesVariable: Variable<[CategoryButtonModel]>
    
    fileprivate var weekStart: Variable<Int>
    
    fileprivate let emptyDaysStart: Int
    fileprivate let emptyDaysEnd:Int
    
    private let categoryProvider: DefaultCategoryProvider
    
    init(timeService: TimeService, timeSlotService: TimeSlotService, settingsService: SettingsService)
    {
        self.timeService = timeService
        self.timeSlotService = timeSlotService
        self.settingsService = settingsService
        
        categoryProvider = DefaultCategoryProvider(timeSlotService: timeSlotService)
        topCategoriesVariable = Variable(
            Array(categoryProvider.getAll()[0..<8]).enumerated()
                .map { index, category in
                    CategoryButtonModel(category: category, enabled: index < 3)
            }
        )
        
        emptyDaysStart = settingsService.installDate!.dayOfWeek - 1
        emptyDaysEnd = 7 - timeService.now.dayOfWeek
        
        weekStart = Variable<Int>(0)
        
        weekTitle = weekStart.asObservable()
            .map { index in
                if index == 0
                {
                    return "This week"
                }
                
                if index == 7
                {
                    return "Last week"
                }
                
                let date = timeService.now.add(days: -index)
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en-US")
                dateFormatter.dateFormat = "MMMM dd"
                return "\(dateFormatter.string(from:date)) - \(dateFormatter.string(from: date.add(days:6)))"
        }
        
        weekActivities = weekStart.asObservable()
            .map { [unowned self] index in
                return self.timeService.now.add(days: self.emptyDaysEnd-index)            }
            .map { [unowned self] date in
                let activities = self.timeSlotService.getActivities(fromDate: date.add(days: -6), untilDate: date)
                let totalDuration = activities.totalDurations
                return activities.map {
                    return ($0, $0.duration / totalDuration)
                }
            }
    }
    
    func nextWeek()
    {
        if weekStart.value + 7 < totalNumberOfEntries() - 7
        {
            weekStart.value = weekStart.value + 7
        } else {
            weekStart.value = totalNumberOfEntries() - 7
        }
    }
    
    func previousWeek()
    {
        if weekStart.value - 7 >= 0
        {
            weekStart.value = weekStart.value - 7
        } else {
            weekStart.value = 0
        }
    }
    
    func setFirstDay(index: Int)
    {
        weekStart.value = index
    }
    
    func toggleCategory(category: Category)
    {
        topCategoriesVariable.value = topCategoriesVariable.value
            .map {
                if $0.category == category
                {
                    return CategoryButtonModel(category: $0.category, enabled: !$0.enabled)
                }
                
                return $0
        }
    }
}

extension WeeklySummaryViewModel: ChartViewDatasource
{
    func numberOfLines() -> Int
    {
        return topCategoriesVariable.value.filter({ $0.enabled }).count
    }
    
    func color(forLine line: Int) -> Color
    {
        return topCategoriesVariable.value.filter({ $0.enabled })[line].category.color
    }
    
    func dataPoint(forLine line: Int, atIndex index: Int) -> Activity?
    {
        if index < emptyDaysEnd || index > totalNumberOfEntries() - emptyDaysStart { return nil }
        
        let lineCategory = topCategoriesVariable.value.filter({ $0.enabled })[line].category
        let totalDuration = timeSlotService.getTimeSlots(forDay: timeService.now.add(days: emptyDaysEnd-index))
            .filter({ $0.category ==  lineCategory })
            .map(timeSlotService.calculateDuration)
            .reduce(0, +)
        
        return Activity(category: lineCategory, duration: totalDuration)
    }
    
    func totalNumberOfEntries() -> Int
    {
        return settingsService.installDate!.differenceInDays(toDate: timeService.now) + 1 + emptyDaysEnd + emptyDaysStart
    }
    
    func label(atIndex index: Int) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en-US")
        dateFormatter.dateFormat = "EE\nd"
        let currentDate = timeService.now.add(days: emptyDaysEnd-index)
        return dateFormatter.string(from: currentDate)
    }
}
