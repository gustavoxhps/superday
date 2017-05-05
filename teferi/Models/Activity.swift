import Foundation

struct Activity
{
    let category : Category
    let duration : TimeInterval
}

extension Array where Element == Activity
{
    var totalDurations : TimeInterval
    {
        return self.reduce(0.0, self.sumDuration)
    }
    
    private func sumDuration(accumulator: Double, activity: Activity) -> TimeInterval
    {
        return accumulator + activity.duration
    }
}
