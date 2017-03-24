import Foundation
@testable import teferi

struct TempTimelineTestData
{
    let startOffset : TimeInterval
    let endOffset : TimeInterval?
    let category : teferi.Category
    let includeLocation : Bool
    let includeSmartGuess : Bool
}

extension TempTimelineTestData
{
    init(startOffset: TimeInterval, endOffset: TimeInterval?)
    {
        self.startOffset = startOffset
        self.endOffset = endOffset
        self.category = .unknown
        self.includeSmartGuess = false
        self.includeLocation = false
    }
    
    init(startOffset: TimeInterval,
         endOffset: TimeInterval?,
         _ category: teferi.Category,
         includeSmartGuess: Bool = false,
         includeLocation: Bool = false)
    {
        self.startOffset = startOffset
        self.endOffset = endOffset
        self.category = category
        self.includeSmartGuess = includeSmartGuess
        self.includeLocation = includeLocation
    }
}
