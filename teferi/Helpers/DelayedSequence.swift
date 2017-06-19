import Foundation

class DelayedSequence
{
    private var delay : TimeInterval = 0
    
    private init()
    {
    }
    
    static func start() -> DelayedSequence
    {
        return DelayedSequence()
    }
    
    @discardableResult func wait(_ time: TimeInterval) -> DelayedSequence
    {
        delay += time
        return self
    }
    
    @discardableResult func after(_ time: TimeInterval, _ action: (Double) -> ()) -> DelayedSequence
    {
        delay += time
        action(delay)
        return self
    }
    
    @discardableResult func then(_ action: (Double) -> ()) -> DelayedSequence
    {
        action(delay)
        return self
    }
}
