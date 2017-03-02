import UIKit

class Colors
{
    static let green = rgb(40, 201, 128)
    static let purple = rgb(186, 94, 255)
    static let yellow = rgb(255, 195, 27)
 
    static let darkGray = rgb(94, 91, 91)
    static let offBlack = rgb(4, 4, 6)
    static let lightBlue = rgb(99, 213, 238)
    static let red = rgb(255, 100, 83)
    static let blue = rgb(61, 130, 246)
    static let gray = rgb(206, 205, 205)
    static let lightGray = rgb(206, 205, 205, 0.23)
    static let offBlackTransparent = rgb(4, 4, 6, 0.5)
    
    private static let logoTrancparency = CGFloat(0.64)
    static let transparentPurple = purple.withAlphaComponent(logoTrancparency)
    static let transparentYellow = yellow.withAlphaComponent(logoTrancparency)
    static let transparentGreen = green.withAlphaComponent(logoTrancparency)
    
    private static func rgb(_ r: Int, _ g: Int, _ b: Int, _ a : CGFloat = 1.0) -> UIColor
    {
        return UIColor(r: r, g: g, b: b, a: a)
    }
}
