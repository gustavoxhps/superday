import UIKit
import CoreGraphics
import SnapKit
import RxSwift

///Cell that represents a TimeSlot in the timeline
class TimelineCell : UITableViewCell
{
    // MARK: Fields
    private var currentIndex = 0
    private let hourMask = "%02d h %02d min"
    private let minuteMask = "%02d min"
    
    private lazy var lineHeightConstraint : NSLayoutConstraint =
    {
        return self.lineView.constraints.filter{ $0.firstAttribute == .height }.first!
    }()

    @IBOutlet private weak var lineView : UIView!
    @IBOutlet private weak var slotTime : UILabel!
    @IBOutlet weak var categoryIcon : UIImageView!
    @IBOutlet private weak var elapsedTime : UILabel!
    @IBOutlet private weak var indicatorDot : UIView!
    @IBOutlet private weak var categoryButton : UIButton!
    @IBOutlet private weak var slotDescription : UILabel!
    @IBOutlet private weak var timeSlotDistanceConstraint : NSLayoutConstraint!
    private var lineFadeView : AutoResizingLayerView?
    
    //MARK: Properties
    private(set) var isSubscribedToClickObservable = false
    lazy var editClickObservable : Observable<(CGPoint, Int)> =
    {
        self.isSubscribedToClickObservable = true
        
        return self.categoryButton.rx.tap
            .map { return (self.categoryIcon.convert(self.categoryIcon.center, to: nil), self.currentIndex) }
            .asObservable()
    }()
    
    // MARK: Methods
    override func awakeFromNib()
    {
        super.awakeFromNib()
        self.contentView.isUserInteractionEnabled = false
    }
    
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
    
    /// Updates the icon that indicates the slot's category
    private func layoutCategoryIcon(withAsset asset: Asset, color: UIColor)
    {
        self.categoryIcon.backgroundColor = color
        self.categoryIcon.layer.cornerRadius = 16
        self.categoryIcon.image = UIImage(asset: asset)
    }
    
    /// Updates the label that displays the description and starting time of the slot
    private func layoutDescriptionLabel(withTimelineItem timelineItem: TimelineItem)
    {
        let timeSlot = timelineItem.timeSlot
        let shouldShowCategory = !timelineItem.shouldDisplayCategoryName || timeSlot.category == .unknown
        let categoryText = shouldShowCategory ? "" : timeSlot.category.name
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
        self.lineHeightConstraint.constant = newHeight
        
        self.lineView.backgroundColor = color
        
        if lastInPastDay
        {
            self.ensureLineFadeExists()
        }
        self.lineFadeView?.isHidden = !lastInPastDay
        
        self.lineView.layoutIfNeeded()
        
        self.indicatorDot.backgroundColor = color
        self.indicatorDot.isHidden = !isRunning
        self.indicatorDot.layoutIfNeeded()
    }
    
    private func ensureLineFadeExists()
    {
        guard self.lineFadeView == nil else { return }
        
        let bottomFadeStartColor = Color.white.withAlphaComponent(1.0)
        let bottomFadeEndColor = Color.white.withAlphaComponent(0.0)
        let bottomFadeOverlay = self.fadeOverlay(startColor: bottomFadeStartColor, endColor: bottomFadeEndColor)
        let fadeView = AutoResizingLayerView(layer: bottomFadeOverlay)
        self.lineView.addSubview(fadeView)
        fadeView.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.lessThanOrEqualToSuperview()
            make.height.equalTo(100).priority(1)
        }
        self.lineFadeView = fadeView
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
