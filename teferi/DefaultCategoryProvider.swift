class DefaultCategoryProvider : CategoryProvider
{
    private let timeSlotService : TimeSlotService
    
    init(timeSlotService : TimeSlotService)
    {
        self.timeSlotService = timeSlotService
    }
    
    func getAll(but categoriesToFilter: Category...) -> [Category]
    {
        return Category.allSorted(byUsage: self.timeSlotService.getTimeSlots(sinceDaysAgo: 14)).filter { !categoriesToFilter.contains($0) }
    }
}
