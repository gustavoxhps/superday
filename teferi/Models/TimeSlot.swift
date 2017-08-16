import Foundation
import CoreData
import CoreLocation

struct TimeSlot
{
    // MARK: Properties
    let startTime: Date
    let endTime: Date?
    let category: Category
    let smartGuessId : Int?
    let location: CLLocation?
    let categoryWasSetByUser: Bool
    
}

extension TimeSlot
{
    init(withStartTime startTime: Date, endTime: Date? = nil, category: Category, categoryWasSetByUser: Bool, location: CLLocation? = nil)
    {
        self.startTime = startTime
        self.endTime = endTime
        self.category = category
        self.smartGuessId = nil
        self.location = location
        self.categoryWasSetByUser = categoryWasSetByUser
        
    }
    
    init(withStartTime time: Date, endTime: Date? = nil, smartGuess: SmartGuess, location: CLLocation?)
    {
        self.startTime = time
        self.endTime = endTime
        self.category = smartGuess.category
        self.smartGuessId = smartGuess.id
        self.location = location
        self.categoryWasSetByUser = false

    }
}

extension TimeSlot
{
    func withCategory(_ category: Category, setByUser: Bool? = nil) -> TimeSlot
    {
        return TimeSlot(
            withStartTime: self.startTime,
            endTime: self.endTime,
            category: category,
            categoryWasSetByUser: setByUser ?? self.categoryWasSetByUser,
            location: self.location
        )
    }
    
    func withEndDate( _ endDate: Date) -> TimeSlot
    {
        return TimeSlot(
            startTime: self.startTime,
            endTime: endDate,
            category: self.category,
            smartGuessId: self.smartGuessId,
            location: self.location,
            categoryWasSetByUser: self.categoryWasSetByUser
        )
    }
}

extension TimeSlot
{
    var duration: Double?
    {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}
