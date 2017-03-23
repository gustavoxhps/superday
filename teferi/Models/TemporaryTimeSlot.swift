import Foundation

struct TemporaryTimeSlot
{
    let start : Date
    let end : Date?
    let smartGuess : SmartGuess?
    let category : Category
    let location : Location?
}
