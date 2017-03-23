import Foundation

struct TemporaryTimeSlot
{
    let start : Date
    let end : Date?
    let smartGuess : SmartGuess?
    let category : Category
    let location : Location?
}

extension TemporaryTimeSlot
{
    func with(start startTime: Date? = nil,
              end endTime: Date? = nil,
              smartGuess: SmartGuess? = nil,
              category: Category? = nil,
              location: Location? = nil) -> TemporaryTimeSlot
    {
        return TemporaryTimeSlot(start: startTime ?? self.start,
                                 end: endTime ?? self.end,
                                 smartGuess: smartGuess ?? self.smartGuess,
                                 category: category ?? self.category,
                                 location: location ?? self.location)
    }
}
