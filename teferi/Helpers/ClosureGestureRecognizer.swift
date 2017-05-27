import UIKit

class ClosureGestureRecognizer : UITapGestureRecognizer
{
    private let target : ClosureGestureRecognizerTarget
    
    init(withClosure closure: @escaping () -> ())
    {
        target = ClosureGestureRecognizerTarget(withClosure: closure)
        
        super.init(target: target, action: #selector(ClosureGestureRecognizerTarget.runClosure))
    }
}

class ClosureGestureRecognizerTarget : NSObject
{
    private let closure : () -> ()
    
    init(withClosure closure: @escaping () -> ())
    {
        self.closure = closure
        
        super.init()
    }
    
    @objc func runClosure()
    {
        closure()
    }
}
