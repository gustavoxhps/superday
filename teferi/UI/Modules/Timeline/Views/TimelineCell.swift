import UIKit
import CoreGraphics
import SnapKit
import RxSwift
import RxCocoa

///Cell that represents a TimeSlot in the timeline
class TimelineCell : UITableViewCell
{
    // MARK: Public Properties
    var timelineItem: TimelineItem? = nil {
        didSet {
            configure()
        }
    }
    
    private(set) var disposeBag = DisposeBag()
    
    var editClickObservable : Observable<Void> {
        return self.categoryButton.rx.tap
            .asObservable()
    }
    
    var collapseClickObservable : Observable<Void> {
        return self.collapseButton.rx.tap
            .asObservable()
    }
    
    var expandClickObservable : Observable<Void> {
        return self.expandButton.rx.tap
            .asObservable()
    }
    
    
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
    @IBOutlet private weak var dotView : UIView!
    @IBOutlet private weak var collapseButton: UIButton!
    @IBOutlet private weak var expandButton: UIButton!
    
    private var lineFadeView : AutoResizingLayerView?
    
    // MARK: Public Methods
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    func configure()
    {
        guard let timelineItem = timelineItem else { return }
        
        //Updates each one of the cell's components
        layoutLine(withItem: timelineItem)
        layoutSlotTime(withItem: timelineItem, lastInPastDay: timelineItem.isLastInPastDay)
        layoutElapsedTimeLabel(withColor: timelineItem.category.color, interval: timelineItem.duration, shouldShow: true /*TODO*/)
        layoutDescriptionLabel(withTimelineItem: timelineItem)
        layoutCategoryIcon(forCategory: timelineItem.category)
        
        let image = UIImage(asset: Asset.icCollapse).withRenderingMode(.alwaysTemplate)
        collapseButton.setImage(image, for: .normal)
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
    private func layoutCategoryIcon(forCategory category: Category)
    {
        categoryCircle.backgroundColor = category.color
        let image = UIImage(asset: category.icon)!
        let icon = categoryIcon!
        icon.image = image
        icon.contentMode = .scaleAspectFit
    }
    
    /// Updates the label that displays the description and starting time of the slot
    private func layoutDescriptionLabel(withTimelineItem timelineItem: TimelineItem)
    {
        let shouldShowCategory = !timelineItem.shouldDisplayCategoryName || timelineItem.category == .unknown
        let categoryText = shouldShowCategory ? "" : timelineItem.category.description
        slotDescription.text = categoryText
        timeSlotDistanceConstraint.constant = shouldShowCategory ? 0 : 6
    }
    
    /// Updates the label that shows the time the TimeSlot was created
    private func layoutSlotTime(withItem timelineItem: TimelineItem, lastInPastDay: Bool)
    {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let startString = formatter.string(from: timelineItem.startTime)
        
        if lastInPastDay, let endTime = timelineItem.endTime
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
    private func layoutElapsedTimeLabel(withColor color: UIColor, interval: TimeInterval, shouldShow: Bool)
    {
        let minutes = (Int(interval) / 60) % 60
        let hours = (Int(interval) / 3600)
        
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
    private func layoutLine(withItem item: TimelineItem)
    {
        if item.category == .sleep
        {
            lineHeight.constant = 20.0
        }
        else
        {
            let newHeight = Constants.minLineHeight + Constants.timelineSlope * (CGFloat(item.duration) - Constants.minTimelineInterval)
            lineHeight.constant = max(min(newHeight, Constants.maxLineHeight), Constants.minLineHeight)
        }
        
        lineView.color = item.category.color
        dotView.backgroundColor = item.category.color
        
        lineView.fading = item.isLastInPastDay
        
        lineFadeView?.isHidden = !item.isLastInPastDay
        
        dotView.isHidden = !item.isRunning && !item.isLastInPastDay || item.hasCollapseButton
        collapseButton.isHidden = !item.hasCollapseButton
        collapseButton.tintColor = item.category.color
        
        bottomMargin.constant = item.isRunning || item.hasCollapseButton ? 20 : 0
        
        expandButton.isHidden = item.timeSlots.count == 1
        lineView.collapsable = item.timeSlots.count > 1
        
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
