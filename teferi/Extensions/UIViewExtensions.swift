import UIKit

extension UIView
{
    static func animate(withDuration duration: TimeInterval,
                        options: UIViewAnimationOptions, animations: @escaping () -> ())
    {
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: animations, completion: nil)
    }
    
    static func animate(withDuration duration: TimeInterval, delay: TimeInterval,
                 options: UIViewAnimationOptions, animations: @escaping () -> ())
    {
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations, completion: nil)
    }
    
    static func animate(withDuration duration: TimeInterval, delay: TimeInterval,
                 animations: @escaping () -> ())
    {
        UIView.animate(withDuration: duration, delay: delay, options: [], animations: animations, completion: nil)
    }
    
    static func animate(_ changes: @escaping ()->(), duration: Double, delay: Double = 0.0, options: [UIViewAnimationOptions] = [],
        withControlPoints c1x: Float = 0, _ c1y: Float = 0, _ c2x: Float = 0, _ c2y: Float = 0,
        completion: (()->())? = nil)
    {
        let timingFunction = CAMediaTimingFunction(controlPoints: c1x, c1y, c2x, c2y)
        
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(timingFunction)
        
        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: [],
            animations: changes) { (_) in
                completion?()
        }
        
        CATransaction.commit()
    }

    static func scheduleAnimation(withDelay delay: TimeInterval, duration: TimeInterval,
                                  options: UIViewAnimationOptions, animations: @escaping () -> ())
    {
        Timer.schedule(withDelay: delay)
        {
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: animations, completion: nil)
        }
    }
    
    static func scheduleAnimation(withDelay delay: TimeInterval, duration: TimeInterval, animations: @escaping () -> ())
    {
        Timer.schedule(withDelay: delay)
        {
            UIView.animate(withDuration: duration, delay: 0, options: [], animations: animations, completion: nil)
        }
    }
    
    func constrainEdges(to view: UIView)
    {
        self.snp.makeConstraints { make in make.edges.equalTo(view) }
    }
}
