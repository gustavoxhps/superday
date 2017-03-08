import UIKit

class OnboardingPage2 : OnboardingPage
{
    @IBOutlet private weak var textView: UIView!
    @IBOutlet private weak var timelineView: UIView!
    
    private var editedTimeSlot : TimeSlot!
    private var timelineCells : [TimelineCell]!
    private var editedCell : TimelineCell!
    private var editView : EditTimeSlotView!
    private var touchCursor : UIImageView!
    private lazy var timeSlots : [TimeSlot] =
    {
        return [
            self.getTimeSlot(withStartTime: self.getDate(addingHours: 10, andMinutes: 30),
                             endTime: self.getDate(addingHours: 11, andMinutes: 0),
                             category: .friends),
            
            self.getTimeSlot(withStartTime: self.getDate(addingHours: 11, andMinutes: 0),
                             endTime: self.getDate(addingHours: 11, andMinutes: 55),
                             category: .work)
        ]
    }()
    
    private let editIndex = 1
    private let editTo = Category.commute
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder, nextButtonText: "Ok, got it")
    }
    
    override func viewDidLoad()
    {   
        let slot = self.timeSlots[self.editIndex]
        self.editedTimeSlot = TimeSlot(withStartTime: slot.startTime,
                                       category: self.editTo,
                                       categoryWasSetByUser: false)
        self.editedTimeSlot.endTime = slot.endTime
        
        self.initAnimatedTitleText(self.textView)
        self.timelineCells = self.initAnimatingTimeline(with: self.timeSlots, in: self.timelineView)
        
        self.editView = EditTimeSlotView()
        self.editView.isUserInteractionEnabled = false
        self.timelineView.addSubview(self.editView)
        self.editView.constrainEdges(to: self.timelineView)
        
        self.editedCell = self.createTimelineCell(for: self.editedTimeSlot)
        self.editedCell.alpha = 0
        
        self.touchCursor = UIImageView(image: UIImage(asset: .icCursor))
        self.touchCursor.alpha = 0
    }
    
    override func startAnimations()
    {
        self.timelineCells[self.editIndex].addSubview(self.editedCell)
        self.timelineView.addSubview(self.touchCursor)
        self.setCursorPosition(toX: 100, y: 200)
        
        DelayedSequence.start()
            .then {t in self.animateTitleText(self.textView, duration: 0.5, delay: t)}
            .after(0.3) {t in self.animateTimeline(self.timelineCells, delay: t)}
            .after(0.9, self.showCursor)
            .after(0.3, self.moveCursorToCell)
            .after(0.6, self.tapCursor)
            .after(0.2, self.openEditView)
            .after(0.8, self.moveCursorToCategory)
            .after(0.5, self.tapCursor)
            .after(0.2, self.onTappedEditCategory)
            .after(0.3, self.closeEditView)
            .after(0.15, self.hideCursor)
            .after(0.5, self.changeTimeSlot)
    }
    
    private func openEditView(delay: TimeInterval)
    {
        Timer.schedule(withDelay: delay)
        {
            let cell = self.timelineCells[self.editIndex]
            let slot = self.timeSlots[self.editIndex]
            self.editView.onEditBegan(
                point: cell.categoryCircle.convert(cell.categoryCircle.center, to: self.timelineView),
                timeSlot: slot)
        }
    }
    
    private func closeEditView(delay : TimeInterval)
    {
        Timer.schedule(withDelay: delay)
        {
            self.editView.isEditing = false
        }
    }
    
    private func changeTimeSlot(delay: TimeInterval)
    {
        UIView.scheduleAnimation(withDelay: delay, duration: 0.4)
        {
            self.editedCell.alpha = 1
        }
    }
    
    private func showCursor(delay: TimeInterval)
    {
        UIView.scheduleAnimation(withDelay: delay, duration: 0.2, options: .curveEaseOut)
        {
            self.touchCursor.alpha = 1
        }
    }
    private func hideCursor(delay: TimeInterval)
    {
        UIView.scheduleAnimation(withDelay: delay, duration: 0.2, options: .curveEaseIn)
        {
            self.touchCursor.alpha = 0
        }
    }
    
    private func moveCursorToCell(delay : TimeInterval)
    {
        moveCursor(to: {
            let view = self.timelineCells[self.editIndex].categoryCircle!
            return view.convert(view.center, to: self.editView)
        }, offset: CGPoint(x: -16, y: -8), delay: delay)
    }
    
    private func moveCursorToCategory(delay: TimeInterval)
    {
        moveCursor(to: {
            let view = self.editView.getIcon(forCategory: self.editTo)!
            return view.convert(view.center, to: nil)
        }, offset: CGPoint(x: 0, y: 0), delay: delay)
    }
    
    private func moveCursor(to getPoint: @escaping () -> CGPoint, offset: CGPoint, delay: TimeInterval)
    {
        UIView.scheduleAnimation(withDelay: delay, duration: 0.45, options: .curveEaseInOut)
        {
            let point = getPoint()
            self.setCursorPosition(toX: point.x + offset.x, y: point.y + offset.y)
        }
    }
    
    private func setCursorPosition(toX x: CGFloat, y: CGFloat)
    {
        let frame = self.touchCursor.frame.size
        let w = frame.width
        let h = frame.height
        
        self.touchCursor.frame = CGRect(x: x - w / 2, y: y - h / 2, width: w, height: h)
    }
    
    private func tapCursor(delay : TimeInterval)
    {
        UIView.scheduleAnimation(withDelay: delay, duration: 0.125, options: .curveEaseOut)
        {
            self.touchCursor.transform = CGAffineTransform.init(scaleX: 0.8, y: 0.8)
        }
        
        UIView.scheduleAnimation(withDelay: delay + 0.15, duration: 0.125, options: .curveEaseIn)
        {
            self.touchCursor.transform = CGAffineTransform.init(scaleX: 1, y: 1)
        }
    }
    
    private func onTappedEditCategory(delay : TimeInterval)
    {
        Timer.schedule(withDelay: delay)
        {
            let view = self.editView.getIcon(forCategory: self.editTo)!
            UIView.scheduleAnimation(withDelay: 0, duration: 0.15, options: .curveEaseOut)
            {
                view.alpha = 0.6
            }
            
            UIView.scheduleAnimation(withDelay: 0.15, duration: 0.15, options: .curveEaseIn)
            {
                view.alpha = 1
            }
        }
    }
}
