import Foundation

extension TimeSlotService
{
    func getActivities(forDate date: Date) -> [Activity]
    {
        let result = getTimeSlots(forDay: date)
                        .groupBy(category)
                        .map(toActivity)
        
        return result
    }
    
    func getActivities(fromDate startDate:Date, untilDate endDate:Date) -> [Activity]
    {
        return getTimeSlots(betweenDate: startDate, andDate: endDate)
            .groupBy(category)
            .map(toActivity)
    }
    
    private func category(of timeSlot: TimeSlot) -> Category
    {
        return timeSlot.category
    }
    
    private func toActivity(_ timeSlots: [TimeSlot]) -> Activity
    {
        let totalTime =
            timeSlots
                .map(calculateDuration)
                .reduce(0, +)
        
        return Activity(category: timeSlots.first!.category, duration: totalTime)
    }
}
