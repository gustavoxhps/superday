import UIKit
import CoreGraphics

class AddTimeSlotButton : MaterialButton
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup()
    {
        // This is necessary in order for the rotation to work. Otherwise we have to use a UIView insteado of a UIButton subclass
        imageView?.clipsToBounds = false
        imageView?.contentMode = .center
    }
    
    func changeState(isAdding:Bool)
    {
        let degrees = isAdding ? 45.0 : 0.0
        let options = isAdding ? UIViewAnimationOptions.curveEaseOut : UIViewAnimationOptions.curveEaseIn
        
        let delay : TimeInterval = 0

        UIView.animate(withDuration: 0.2, delay: delay,
                       options: options,
                       animations:
            {
                self.imageView!.transform = CGAffineTransform(rotationAngle: CGFloat(degrees * (Double.pi / 180.0)));
            },
            completion: nil
        )
    }
}
