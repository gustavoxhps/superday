import UIKit

class AutoResizingLayerView: UIView
{
    private var caLayer: CALayer
    
    init(layer caLayer: CALayer)
    {
        self.caLayer = caLayer
        
        //Set to arbitrary "starter" frame (Use autolayout to change in usage.)
        super.init(frame: UIScreen.main.bounds)
            
        self.layer.addSublayer(self.caLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews()
    {
        caLayer.frame = self.bounds
    }
}
