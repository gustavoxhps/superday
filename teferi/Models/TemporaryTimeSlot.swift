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
    func with(end endTime: Date) -> TemporaryTimeSlot
    {
        return TemporaryTimeSlot(start: self.start,
                                 end: endTime,
                                 smartGuess: self.smartGuess,
                                 category: self.category,
                                 location: self.location)
    }
}
