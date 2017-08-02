import UIKit
import CoreGraphics
import RxSwift

protocol ChartViewDatasource
{
    func numberOfLines() -> Int
    func dataPoint(forLine: Int, atIndex: Int) -> Activity?
    func totalNumberOfEntries() -> Int
    func label(atIndex: Int) -> String
}

protocol ChartViewDelegate
{
    func pageChange(index: Int)
}

enum CachedDataPoint
{
    case empty
    case data(activity:Activity)
    
    var duration: TimeInterval
    {
        switch self {
        case .empty:
            return 0
        case .data(let activity):
            return activity.duration
        }
    }
}

class ChartView: UIView
{
    // Constants
    private let insets:UIEdgeInsets = UIEdgeInsets(top: 0, left: 47, bottom: 44, right: 23)
    private let pointRadius: CGFloat = 3
    private let hoursInterval: TimeInterval = 5
    private var yAxixInterval: TimeInterval { return hoursInterval * 60 * 60 }
    
    // Private Properties
    private var topYValue: TimeInterval?
    private var nextTopYValue: TimeInterval = 0
    fileprivate var offset: CGFloat = 0
    fileprivate var pageWidth: CGFloat = 0

    private var dataPointsCache: [String:CachedDataPoint] = [String:CachedDataPoint]()
    private var labelsCache: [Int:String] = [Int:String]()
    
    private var scrollView: UIScrollView!
    private var displayLink: CADisplayLink? = nil
    
    // Public Properties
    var delegate: ChartViewDelegate? = nil
    var datasource: ChartViewDatasource?
    {
        didSet
        {
            setNeedsDisplay()
        }
    }
    
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
    
    private func setup()
    {
        scrollView = UIScrollView(frame: frame)
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        addSubview(scrollView)
        
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        guard let datasource = datasource else { return }
        
        pageWidth = (frame.width - insets.left - insets.right) / 6
        let numberOfXPoints = CGFloat(datasource.totalNumberOfEntries())
        scrollView.contentSize = CGSize(width: pageWidth * numberOfXPoints, height: frame.height)
        scrollView.contentOffset = CGPoint(x: scrollView.contentSize.width - frame.width, y: 0)

    }
    
    // Public Methods
    func setWeekStart(index:Int)
    {
        scrollView.setContentOffset(CGPoint(x:scrollView.contentSize.width - frame.width - CGFloat(index) * pageWidth, y:0), animated: true)
    }
    
    func refresh()
    {
        dataPointsCache = [String:CachedDataPoint]()
        startHeightAnimation()
        setNeedsDisplay()
    }
    
    // Private Methods
    internal override func draw(_ rect: CGRect)
    {
        if topYValue == nil {
            let higherValue = self.getHigherValue()
            guard higherValue > 0 else { return }
            topYValue = ceil(higherValue / self.yAxixInterval) * self.yAxixInterval
        }
        
        let insetRect = CGRect(x: insets.left,
                               y: insets.top,
                               width: rect.width - insets.left - insets.right,
                               height: rect.height - insets.top - insets.bottom)
        
        drawBackgroundLines(rect: CGRect(x: rect.origin.x,
                                         y: insetRect.origin.y,
                                         width: rect.width,
                                         height: insetRect.height))
        drawChart(inRect: insetRect)
        drawLabels(inRect: insetRect)
    }
    
    private func drawBackgroundLines(rect:CGRect)
    {
        guard let ctx = UIGraphicsGetCurrentContext(), let topYValue = topYValue else { return }
        
        for l in 0...Int(floor(topYValue / yAxixInterval))
        {
            let lineHeight = rect.height - rect.height * CGFloat((TimeInterval(l) * yAxixInterval) / topYValue)
            
            ctx.move(to: CGPoint(x: 0, y: lineHeight))
            ctx.addLine(to: CGPoint(x: rect.width, y: lineHeight))
            
            let text = NSAttributedString(string: "\(l * Int(hoursInterval)) h",
                attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 11),
                             NSForegroundColorAttributeName: Style.Color.gray])
            text.draw(at: CGPoint(x: 16, y: lineHeight-16))
        }

        ctx.setLineWidth(0.5)
        Color.lightGray.setStroke()
        ctx.drawPath(using: .stroke)
    }
    
    private func drawChart(inRect rect: CGRect)
    {
        guard let ctx = UIGraphicsGetCurrentContext(),
            let datasource = datasource else { return }
        
        ctx.saveGState()
        ctx.clip(to: rect.insetBy(dx: -pointRadius-1, dy: -pointRadius-1))
        
        for l in 0..<datasource.numberOfLines()
        {
            drawLine(l, inRect:rect)
            drawPoints(l, inRect: rect)
        }

        ctx.restoreGState()
    }
    
    private func drawLine(_ line:Int, inRect rect:CGRect)
    {
        guard let ctx = UIGraphicsGetCurrentContext(), let topYValue = topYValue else { return }

        ctx.beginPath()
        
        var lastPoint: CGPoint? = nil
        var category:Category? = nil
        
        var hasAnyValue = false
        let currentPage = max(Int(offset / pageWidth), 0)
        
        for page in currentPage...(currentPage + 7)
        {
            guard case let CachedDataPoint.data(activity: dataPoint) = dataPoint(ofLine: line, withIndex: page) else { continue }
        
            hasAnyValue = hasAnyValue || dataPoint.duration > 0
            
            let point = CGPoint(x: rect.origin.x + rect.width - CGFloat(page) * pageWidth + offset,
                                y: rect.height - rect.height * CGFloat(dataPoint.duration / topYValue))
            
            if let lastPoint = lastPoint {
                ctx.move(to: lastPoint)
                ctx.addLine(to: point)
            } else {
                ctx.move(to: point)
            }
            
            category = dataPoint.category
            lastPoint = point
        }
        
        if hasAnyValue
        {
            category?.color.setStroke()
            ctx.setLineWidth(2)
            ctx.drawPath(using: .stroke)
        }
    }
    
    
    private func drawPoints(_ line: Int, inRect rect:CGRect)
    {
        guard let ctx = UIGraphicsGetCurrentContext(), let topYValue = topYValue else { return }

        ctx.beginPath()
        
        var category:Category? = nil
        
        var hasAnyValue = false
        let currentPage = max(Int(offset / pageWidth), 0)
        
        for page in currentPage...(currentPage + 7)
        {
            guard case let CachedDataPoint.data(activity: dataPoint) = dataPoint(ofLine: line, withIndex: page) else { continue }
            
            hasAnyValue = hasAnyValue || dataPoint.duration > 0

            let point = CGPoint(x: rect.origin.x + rect.width - CGFloat(page) * pageWidth + offset,
                                y: rect.height - rect.height * CGFloat(dataPoint.duration / topYValue))
        
            ctx.addEllipse(in: CGRect(x: point.x - pointRadius,
                                      y: point.y - pointRadius,
                                      width: pointRadius*2,
                                      height: pointRadius*2))

            category = dataPoint.category
        }
        
        if hasAnyValue
        {
            Color.white.setFill()
            category?.color.setStroke()
            ctx.setLineWidth(2)
            ctx.drawPath(using: .fillStroke)
        }
    }
    
    private func drawLabels(inRect rect: CGRect)
    {
        guard let ctx = UIGraphicsGetCurrentContext(), let datasource = datasource else { return }
        
        ctx.saveGState()
        ctx.clip(to: rect.insetBy(dx: -15, dy: -insets.bottom-1))
        
        let currentPage = max(Int(offset / pageWidth), 0)
        
        for page in currentPage...(currentPage + 7)
        {
            var label: String? = labelsCache[page]
            if label == nil {
                label = datasource.label(atIndex: page)
                labelsCache[page] = label
            }
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let text = NSAttributedString(string: label!,
                                          attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 11),
                                                       NSForegroundColorAttributeName: Style.Color.gray,
                                                       NSParagraphStyleAttributeName: paragraphStyle])
            
            text.draw(in: CGRect(x: rect.origin.x + rect.width - CGFloat(page) * pageWidth + offset - 15,
                                 y: rect.height + 8,
                                 width: 30,
                                 height: 36))
        }
        
        ctx.restoreGState()
    }
    
    private func dataPoint(ofLine line:Int, withIndex p:Int) -> CachedDataPoint
    {
        guard let datasource = datasource else { return .empty }

        guard let cachedDataPoint = dataPointsCache["\(line):\(p)"] else {
            guard let activity = datasource.dataPoint(forLine: line, atIndex: p) else {
                dataPointsCache["\(line):\(p)"] = .empty
                return .empty
            }
            let cached = CachedDataPoint.data(activity: activity)
            dataPointsCache["\(line):\(p)"] = cached
            return cached
        }
        
        return cachedDataPoint
    }
    
    fileprivate func snapToClosestPage()
    {
        let page = Int(round((scrollView.contentSize.width - frame.width - scrollView.contentOffset.x) / pageWidth))
        self.scrollView.setContentOffset(CGPoint(x:scrollView.contentSize.width - frame.width - CGFloat(page) * self.pageWidth, y:0), animated: true)

        delegate?.pageChange(index: page)
    }
    
    fileprivate func startHeightAnimation()
    {
        let higherValue = self.getHigherValue()
        guard higherValue > 0 else { return }

        self.nextTopYValue = ceil(higherValue / self.yAxixInterval) * self.yAxixInterval
        
        self.displayLink = CADisplayLink(target: self, selector: #selector(ChartView.animateHeight))
        self.displayLink?.add(to: .current, forMode: .commonModes)
    }
    
    @objc private func animateHeight()
    {
        guard let oldTopYValue = topYValue else { return }
        
        let newTopYValue = oldTopYValue + (nextTopYValue - oldTopYValue) / 20
        if abs(newTopYValue - nextTopYValue) < 0.0001
        {
            displayLink?.invalidate()
            displayLink?.remove(from: .current, forMode: .commonModes)
            displayLink = nil
        }
        
        topYValue = newTopYValue
        setNeedsDisplay()
    }
    
    private func getHigherValue() -> TimeInterval
    {
        guard let datasource = datasource, pageWidth > 0 else { return 0 }
        
        let currentPage = max(Int(offset / pageWidth), 0)

        var higherValue: TimeInterval = 0
        for page in currentPage...(currentPage + 7)
        {
            for line in 0..<datasource.numberOfLines()
            {
                higherValue = max(higherValue, dataPoint(ofLine: line, withIndex: page).duration)
            }
        }
        
        return higherValue
    }
}

extension ChartView : UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        offset = scrollView.contentSize.width - scrollView.contentOffset.x - frame.width
        
        setNeedsDisplay()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        snapToClosestPage()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        guard !decelerate else { return }
        
        snapToClosestPage()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    {
        startHeightAnimation()
    }
}
