import UIKit

class LaunchAnimationView : UIView
{
    // MARK: Fields
    private var background = CALayer()
    private var dots = [CALayer]()
    
    // MARK: Initializers
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        self.background.frame = frame
        self.background.backgroundColor = Color.white.cgColor
        self.layer.addSublayer(background)
        
        let colors = [Colors.green, Colors.purple, Colors.transparentPurple,
                      Colors.transparentGreen, Colors.yellow, Colors.purple,
                      Colors.green, Colors.transparentYellow, Colors.yellow]
        
        let dotSize = CGFloat(20)
        let dotMargin = CGFloat(8.0)
        let dotStep = dotSize + dotMargin
        let centerOffset = dotSize * 1.5 + dotMargin
        let offsetX = frame.width / 2 - centerOffset
        let offsetY = frame.height / 2 - centerOffset
        let cornerRadius = dotSize / 2
        
        for i in 0..<9
        {
            let dot = CALayer()
            
            let row = CGFloat(i / 3)
            let column = CGFloat(i % 3)
            
            dot.frame = CGRect(
                x: offsetX + dotStep * column,
                y: offsetY + dotStep * row,
                width: dotSize,
                height: dotSize
            )
            
            dot.backgroundColor = colors[i].cgColor
            dot.cornerRadius = cornerRadius
            
            self.dots.append(dot)
            self.layer.addSublayer(dot)
        }
    }
    
    // MARK: Actions
    func animate(onCompleted: @escaping (Void) -> Void)
    {
        let animationOrder = [0, 8, 2, 6, 1, 7, 3, 5, 4]
        
        let duration = 0.15
        let interval = 0.1
        let lastDuration = 0.25
        
        for i in 0..<8
        {
            self.animateDot(self.dots[animationOrder[i]], duration: duration, delay: Double(i) * interval)
        }
        
        self.animateDot(self.dots[animationOrder[8]], duration: lastDuration, delay: 8 * interval)
        
        animateLayer(background, duration: duration * 3, delay: duration * 5, animation:
            { _ in
                self.background.opacity = 0
            }, properties: "opacity")
        
        Timer.schedule(withDelay: duration * 8 + lastDuration) { _ in onCompleted() }
    }
    
    private func animateDot(_ dot: CALayer, duration: Double, delay: Double)
    {
        animateLayer(dot, duration: duration, delay: delay, animation:
            { _ in
                let f = dot.frame
                dot.frame = CGRect(x: f.origin.x + f.width / 2, y: f.origin.y + f.width / 2, width: 0, height: 0)
                dot.cornerRadius = 0
            }, properties: "position", "bounds", "cornerRadius")
    }
}
