import Foundation

enum CustomEvent
{
    case timeSlotManualCreation(date: Date, category: Category)
    case timeSlotEditing(date: Date, fromCategory: Category, toCategory: Category, duration: Double?)
    case timeSlotCreated(date: Date, category: Category, duration: Double?)
    case timeSlotSmartGuessed(date: Date, category: Category, duration: Double?)
    case timeSlotNotSmartGuessed(date: Date, category: Category, duration: Double?)
    case timelineVote(date: Date, vote: Bool)
    
    var name : String
    {
        switch self {
        case .timeSlotManualCreation(_):
            return "Manual TimeSlot Creation"
        case .timeSlotEditing(_):
            return "TimeSlot Editing"
        case .timeSlotCreated(_):
            return "TimeSlot Created"
        case .timeSlotSmartGuessed(_):
            return "TimeSlot SmartGuessed"
        case .timeSlotNotSmartGuessed(_):
            return "TimeSlot Not SmartGuessed"
        case .timelineVote(_):
            return "Timeline Vote"
        }
    }
    
    var attributes : [String: Any]
    {
        var attributesToReturn : [String: Any] = ["regionCode": Locale.current.regionCode ?? ""]
        
        switch self {
        case .timeSlotManualCreation(let date, let category):

            attributesToReturn["localHour"] = date.hour
            attributesToReturn["dayOfWeek"] = date.dayOfWeek
            attributesToReturn["category"] = category.rawValue
            
        case .timeSlotEditing(let date, let fromCategory, let toCategory, let duration):
            
            attributesToReturn["localHour"] = date.hour
            attributesToReturn["dayOfWeek"] = date.dayOfWeek
            attributesToReturn["fromCategory"] = fromCategory.rawValue
            attributesToReturn["toCategory"] = toCategory.rawValue
            attributesToReturn["duration"] = duration ?? -1
            
        case .timeSlotCreated(let date, let category, let duration),
             .timeSlotSmartGuessed(let date, let category, let duration),
             .timeSlotNotSmartGuessed(let date, let category, let duration):
            
            attributesToReturn["localHour"] = date.hour
            attributesToReturn["dayOfWeek"] = date.dayOfWeek
            attributesToReturn["category"] = category.rawValue
            attributesToReturn["duration"] = duration ?? -1
            
        case .timelineVote(let date, let vote):
            
            attributesToReturn["localHour"] = date.hour
            attributesToReturn["dayOfWeek"] = date.dayOfWeek
            attributesToReturn["vote"] = vote ? "+" : "-"
        }
        
        return attributesToReturn
    }
}
