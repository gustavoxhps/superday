import UIKit
import CoreGraphics
import SnapKit
import RxSwift
import RxCocoa

///Cell that represents a TimeSlot in the timeline
class TimelineCell : UITableViewCell
{
    // MARK: Fields
    private var currentIndex = 0
    private let hourMask = "%02d h %02d min"
    private let minuteMask = "%02d min"
    
    @IBOutlet private(set) weak var contentHolder: UIView!
    @IBOutlet private(set) weak var lineView : LineView!
    @IBOutlet private(set) weak var slotTime : UILabel!
    @IBOutlet private(set) weak var elapsedTime : UILabel!
    @IBOutlet private(set) weak var categoryButton : UIButton!
    @IBOutlet private(set) weak var slotDescription : UILabel!
    @IBOutlet private(set) weak var timeSlotDistanceConstraint : NSLayoutConstraint!
    @IBOutlet private(set) weak var categoryCircle: UIView!
    @IBOutlet private(set) weak var categoryIcon: UIImageView!
    @IBOutlet private(set) weak var lineHeight: NSLayoutConstraint!
    @IBOutlet private(set) weak var bottomMargin: NSLayoutConstraint!
    @IBOutlet private(set) weak var dotsView : DottedLineView!
    
    private var lineFadeView : AutoResizingLayerView?
    
    let disposeBag = DisposeBag()
    
    //MARK: Properties
    private(set) var isSubscribedToClickObservable = false
    lazy var editClickObservable : Observable<(CGPoint, Int)> =
        {
            self.isSubscribedToClickObservable = true
            
            return self.categoryButton.rx.tap
                .map { return (self.categoryCircle.convert(self.categoryCircle.center, to: nil), self.currentIndex) }
                .asObservable()
    }()
    
    // MARK: Methods
    /**
     Binds the current TimeSlot in order to change the UI accordingly.
     
     - Parameter timeSlot: TimeSlot that will be bound.
     */
    func bind(toTimelineItem timelineItem: TimelineItem, index: Int, duration: TimeInterval)
    {
        self.currentIndex = index
        
        let timeSlot = timelineItem.timeSlot
        let isRunning = timeSlot.endTime == nil
        let interval = Int(duration)
        let totalInterval = Int(isRunning ? timelineItem.durations.dropLast(1).reduce(duration, +) : timelineItem.durations.reduce(0.0, +))
        let categoryColor = timeSlot.category.color
        
        //Updates each one of the cell's components
        self.layoutLine(withColor: categoryColor, interval: interval, isRunning: isRunning, lastInPastDay: timelineItem.lastInPastDay)
        self.layoutSlotTime(withTimeSlot: timeSlot, lastInPastDay: timelineItem.lastInPastDay)
        self.layoutElapsedTimeLabel(withColor: categoryColor, interval: totalInterval, shouldShow: timelineItem.durations.count > 0)
        self.layoutDescriptionLabel(withTimelineItem: timelineItem)
        self.layoutCategoryIcon(withAsset: timeSlot.category.icon, color: categoryColor)
    }
    
    func animateIntro()
    {
        self.categoryCircle.transform = CGAffineTransform(scaleX: 0, y: 0)
        UIView.animate(
            withDuration: 0.39,
            options: UIViewAnimationOptions.curveEaseInOut) {
                self.categoryCircle.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        self.contentHolder.alpha = 0
        self.contentHolder.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(
            withDuration: 0.492,
            options: UIViewAnimationOptions.curveEaseInOut) {
                self.contentHolder.transform = CGAffineTransform.identity
                self.contentHolder.alpha = 1
        }
    }
    
    /// Updates the icon that indicates the slot's category
    private func layoutCategoryIcon(withAsset asset: Asset, color: UIColor)
    {
        self.categoryCircle.backgroundColor = color
        let image = UIImage(asset: asset)!
        let icon = self.categoryIcon!
        icon.image = image
        icon.contentMode = .scaleAspectFit
    }
    
    /// Updates the label that displays the description and starting time of the slot
    private func layoutDescriptionLabel(withTimelineItem timelineItem: TimelineItem)
    {
        let timeSlot = timelineItem.timeSlot
        let shouldShowCategory = !timelineItem.shouldDisplayCategoryName || timeSlot.category == .unknown
        let categoryText = shouldShowCategory ? "" : timeSlot.category.description
        self.slotDescription.text = categoryText
        self.timeSlotDistanceConstraint.constant = shouldShowCategory ? 0 : 6
    }
    
    /// Updates the label that shows the time the TimeSlot was created
    private func layoutSlotTime(withTimeSlot timeSlot: TimeSlot, lastInPastDay: Bool)
    {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let startString = formatter.string(from: timeSlot.startTime)
        
        if lastInPastDay, let endTime = timeSlot.endTime
        {
            let endString = formatter.string(from: endTime)
            self.slotTime.text = startString + " - " + endString
        }
        else
        {
            self.slotTime.text = startString
        }
    }
    
    /// Updates the label that shows how long the slot lasted
    private func layoutElapsedTimeLabel(withColor color: UIColor, interval: Int, shouldShow: Bool)
    {
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        
        if shouldShow
        {
            self.elapsedTime.textColor = color
            self.elapsedTime.text = hours > 0 ? String(format: hourMask, hours, minutes) : String(format: minuteMask, minutes)
        }
        else
        {
            self.elapsedTime.text = ""
        }
    }
    
    /// Updates the line that displays shows how long the TimeSlot lasted
    private func layoutLine(withColor color: UIColor, interval: Int, isRunning: Bool, lastInPastDay: Bool = false)
    {
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        
        let newHeight = CGFloat(Constants.minLineSize * (1 + (minutes / 15) + (hours * 4)))
        self.lineHeight.constant = max(newHeight, 18)
        
        self.lineView.color = color
        self.dotsView.color = color
        
        self.lineView.fading = lastInPastDay
        
        self.lineFadeView?.isHidden = !lastInPastDay
        
        self.dotsView.isHidden = !isRunning && !lastInPastDay
        self.bottomMargin.constant = isRunning ? 24 : 0
        
        self.lineView.layoutIfNeeded()
    }
    
    /// Configure the fade overlay
    private func fadeOverlay(startColor: UIColor, endColor: UIColor) -> CAGradientLayer
    {
        let fadeOverlay = CAGradientLayer()
        fadeOverlay.colors = [startColor.cgColor, endColor.cgColor]
        fadeOverlay.locations = [0.1]
        fadeOverlay.startPoint = CGPoint(x: 0.0, y: 1.0)
        fadeOverlay.endPoint = CGPoint(x: 0.0, y: 0.0)
        return fadeOverlay
    }
}
