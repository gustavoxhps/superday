import Foundation

extension Array
{
    func firstOfType<T>() -> T
    {
        return flatMap { $0 as? T }.first!
    }
    
    func lastOfType<T>() -> T
    {
        return flatMap { $0 as? T }.last!
    }
    
    func groupBy<Key: Hashable>(_ selectKey: (Element) -> Key) -> [[Element]]
    {
        var groups = [Key:[Element]]()
        
        for element in self
        {
            let key = selectKey(element)
            
            if case nil = groups[key]?.append(element)
            {
                groups[key] = [element]
            }
        }
        
        return groups.map { $0.value }
    }
    
    func safeGetElement(at index: Int) -> Element?
    {
        let element : Element? = indices.contains(index) ? self[index] : nil
        return element
    }
    
    func splitBy(_ sameGroup: (Element, Element) -> Bool) -> [[Element]]
    {
        var groups = [[Element]]()
        
        for element in self
        {
            guard let lastGroup = groups.last,
                let lastElement = lastGroup.last else {
                    groups = [[element]]
                    continue
            }
            if sameGroup(lastElement, element) {
                groups = groups.dropLast() + [lastGroup + [element]]
                continue
            } else {
                groups = groups + [[element]]
                continue
            }
        }
        
        return groups
    }
}

extension Array where Element : Hashable
{
    func distinct() -> [Element]
    {
        return Array(Set(self))
    }
    
    public func toDictionary<Value: Any>(_ generateElement: (Element) -> Value?) -> [Element: Value]
    {
        var dict = [Element:Value]()
        for key in self
        {
            guard let element = generateElement(key) else { continue }
            dict.updateValue(element, forKey: key)
        }
        return dict
    }
}

extension Array where Element == TemporaryTimeSlot
{
    func withEndSetToStartOfNext() -> [TemporaryTimeSlot]
    {
        var updated = [TemporaryTimeSlot]()
        
        for (currentIndex, slot) in enumerated()
        {
            let nextIndex = index(after: currentIndex)
            
            guard
                nextIndex < endIndex
            else {
                updated.append(slot)
                continue
            }
            
            let nextSlot = self[nextIndex]
            
            updated.append(TemporaryTimeSlot(start: slot.start,
                                             end: nextSlot.start,
                                             smartGuess: slot.smartGuess,
                                             category: slot.category,
                                             location: slot.location))
        }
        
        return updated
    }
}
