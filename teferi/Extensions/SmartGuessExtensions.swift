import Foundation

extension SmartGuess : KNNInstance
{
    var attributes : [KNNAttributeType: AnyObject]
    {
        return [.location: self.location, .timestamp: self.location.timestamp as AnyObject]
    }
    var label : String
    {
        return self.category.rawValue
    }
}
