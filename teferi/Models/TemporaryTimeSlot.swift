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
    init(start: Date)
    {
        self.start = start
        self.end = nil
        self.smartGuess = nil
        self.category = .unknown
        self.location = nil
    }
    
    init(location:Location, category:Category)
    {
        self.start = location.timestamp
        self.end = nil
        self.smartGuess = nil
        self.category = category
        self.location = location
    }
    
    init(location:Location, smartGuess:SmartGuess?)
    {
        self.start = location.timestamp
        self.end = nil
        self.smartGuess = smartGuess
        self.category = smartGuess?.category ?? .unknown
        self.location = location
    }
    
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
    
    var duration : TimeInterval?
    {
        guard let end = self.end else { return nil }
        
        return end.timeIntervalSince(start)
    }
}
