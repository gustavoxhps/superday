import Foundation
import CoreData
import CoreLocation

/// Represents each individual activity performed by the app user.
class TimeSlot
{
    // MARK: Properties
    let startTime : Date
    let location : CLLocation?
    
    var smartGuessId : Int?
    var endTime : Date? = nil
    var category = Category.unknown
    var categoryWasSetByUser : Bool
    
    // MARK: Initializers
    init(withStartTime time: Date, category: Category, categoryWasSetByUser: Bool, location: CLLocation? = nil)
    {
        self.startTime = time
        self.location = location
        self.category = category
        self.categoryWasSetByUser = categoryWasSetByUser
    }
    
    init(withStartTime time: Date, smartGuess: SmartGuess, location: CLLocation?)
    {
        self.startTime = time
        self.location = location
        self.categoryWasSetByUser = false
        self.smartGuessId = smartGuess.id
        self.category = smartGuess.category
    }
}
