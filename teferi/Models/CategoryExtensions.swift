import Foundation

extension Category
{
    static func allSorted(byUsage timeslots:[TimeSlot]) -> [Category]
    {
        let sortedCategories = timeslots
            .groupBy({ $0.category })
            .sorted(by: areInIncreasingOrder)
            .map({ $0.first!.category })
        
        var restOfCategories = Category.all
        
        for category in sortedCategories {
            if let index = restOfCategories.index(of: category) {
                restOfCategories.remove(at: index)
            }
        }
        
        return sortedCategories + restOfCategories
        
    }
    
    private static func areInIncreasingOrder(ts1:[TimeSlot], ts2:[TimeSlot]) -> Bool
    {
        return ts1.count > ts2.count
    }
}
