import UIKit
import CoreGraphics
import SnapKit
import RxSwift
import RxCocoa

///Cell that represents a TimeSlot in the timeline
class TimelineCell : UITableViewCell
{
    // MARK: Public Properties
    private(set) var isSubscribedToClickObservable = false
    
    lazy var editClickObservable : Observable<Int> =
        {
            self.isSubscribedToClickObservable = true
            
            return self.categoryButton.rx.tap
                .map { return self.currentIndex }
                .asObservable()
    }()
    
    @IBOutlet private(set) weak var categoryCircle: UIView!
    
    // MARK: Private Properties
    private var currentIndex = 0
    private let hourMask = "%02d h %02d min"
    private let minuteMask = "%02d min"
    
    @IBOutlet private weak var contentHolder: UIView!
    @IBOutlet private(set) weak var lineView : LineView!
    @IBOutlet private(set) weak var slotTime : UILabel!
    @IBOutlet private(set) weak var elapsedTime : UILabel!
    @IBOutlet private weak var categoryButton : UIButton!
    @IBOutlet private(set) weak var slotDescription : UILabel!
    @IBOutlet private weak var timeSlotDistanceConstraint : NSLayoutConstraint!
    @IBOutlet private(set) weak var categoryIcon: UIImageView!
    @IBOutlet private weak var lineHeight: NSLayoutConstraint!
    @IBOutlet private weak var bottomMargin: NSLayoutConstraint!
    @IBOutlet private weak var dotsView : DottedLineView!
    
    private var lineFadeView : AutoResizingLayerView?
    
    private let disposeBag = DisposeBag()
    
    // MARK: Public Methods

    func bind(toTimelineItem timelineItem: TimelineItem, index: Int, duration: TimeInterval)
    {
        currentIndex = index
        
        let timeSlot = timelineItem.timeSlot
        let isRunning = timeSlot.endTime == nil
        let interval = Int(duration)
        let totalInterval = Int(isRunning ? timelineItem.durations.dropLast(1).reduce(duration, +) : timelineItem.durations.reduce(0.0, +))
        let categoryColor = timeSlot.category.color
        
        //Updates each one of the cell's components
        layoutLine(withCategory: timeSlot.category, interval: interval, isRunning: isRunning, lastInPastDay: timelineItem.lastInPastDay)
        layoutSlotTime(withTimeSlot: timeSlot, lastInPastDay: timelineItem.lastInPastDay)
        layoutElapsedTimeLabel(withColor: categoryColor, interval: totalInterval, shouldShow: timelineItem.durations.count > 0)
        layoutDescriptionLabel(withTimelineItem: timelineItem)
        layoutCategoryIcon(withAsset: timeSlot.category.icon, color: categoryColor)
    }
    
    func animateIntro()
    {
        categoryCircle.transform = CGAffineTransform(scaleX: 0, y: 0)
        UIView.animate(
            withDuration: 0.39,
            options: UIViewAnimationOptions.curveEaseInOut) {
                self.categoryCircle.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        contentHolder.alpha = 0
        contentHolder.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(
            withDuration: 0.492,
            options: UIViewAnimationOptions.curveEaseInOut) {
                self.contentHolder.transform = CGAffineTransform.identity
                self.contentHolder.alpha = 1
        }
    }
    
    // MARK: Private Methods
    
    /// Updates the icon that indicates the slot's category
    private func layoutCategoryIcon(withAsset asset: Asset, color: UIColor)
    {
        categoryCircle.backgroundColor = color
        let image = UIImage(asset: asset)!
        let icon = categoryIcon!
        icon.image = image
        icon.contentMode = .scaleAspectFit
    }
    
    /// Updates the label that displays the description and starting time of the slot
    private func layoutDescriptionLabel(withTimelineItem timelineItem: TimelineItem)
    {
        let timeSlot = timelineItem.timeSlot
        let shouldShowCategory = !timelineItem.shouldDisplayCategoryName || timeSlot.category == .unknown
        let categoryText = shouldShowCategory ? "" : timeSlot.category.description
        slotDescription.text = categoryText
        timeSlotDistanceConstraint.constant = shouldShowCategory ? 0 : 6
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
            slotTime.text = startString + " - " + endString
        }
        else
        {
            slotTime.text = startString
        }
    }
    
    /// Updates the label that shows how long the slot lasted
    private func layoutElapsedTimeLabel(withColor color: UIColor, interval: Int, shouldShow: Bool)
    {
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        
        if shouldShow
        {
            elapsedTime.textColor = color
            elapsedTime.text = hours > 0 ? String(format: hourMask, hours, minutes) : String(format: minuteMask, minutes)
        }
        else
        {
            elapsedTime.text = ""
        }
    }
    
    /// Updates the line that displays shows how long the TimeSlot lasted
    private func layoutLine(withCategory category: Category, interval: Int, isRunning: Bool, lastInPastDay: Bool = false)
    {
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        
        if category == .sleep
        {
            lineHeight.constant = 20.0
        }
        else
        {
            let newHeight = CGFloat(Constants.minLineSize * (1 + (minutes / 15) + (hours * 4)))
            lineHeight.constant = max(newHeight, 18)
        }
        
        lineView.color = category.color
        dotsView.color = category.color
        
        lineView.fading = lastInPastDay
        
        lineFadeView?.isHidden = !lastInPastDay
        
        dotsView.isHidden = !isRunning && !lastInPastDay
        bottomMargin.constant = isRunning ? 24 : 0
        
        lineView.layoutIfNeeded()
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
