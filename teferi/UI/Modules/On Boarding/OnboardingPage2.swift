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
            self.viewModel.timeSlot(withCategory:.friends, from:"10:30", to: "11:00"),
            self.viewModel.timeSlot(withCategory:.work, from:"11:00", to: "11:55")
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
        super.viewDidLoad()
        
        let slot = timeSlots[editIndex]
        editedTimeSlot = slot.withCategory(editTo)
        
        initAnimatedTitleText(textView)
        timelineCells = initAnimatingTimeline(with: timeSlots, in: timelineView)
        
        editView = EditTimeSlotView(categoryProvider: OnboardingCategoryProvider(withFirstCategory: editTo))

        editView.isUserInteractionEnabled = false
        timelineView.addSubview(editView)
        editView.constrainEdges(to: timelineView)
        
        editedCell = createTimelineCell(for: editedTimeSlot)
        editedCell.alpha = 0
        
        touchCursor = UIImageView(image: UIImage(asset: .icCursor))
        touchCursor.alpha = 0
    }
    
    override func startAnimations()
    {
        timelineCells[editIndex].addSubview(editedCell)
        editedCell.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        timelineView.addSubview(touchCursor)
        setCursorPosition(toX: 100, y: 200)
        
        DelayedSequence.start()
            .then {t in animateTitleText(textView, duration: 0.5, delay: t)}
            .after(0.3) {t in animateTimeline(timelineCells, delay: t)}
            .after(0.9, showCursor)
            .after(0.3, moveCursorToCell)
            .after(0.6, tapCursor)
            .after(0.2, openEditView)
            .after(0.8, moveCursorToCategory)
            .after(0.5, tapCursor)
            .after(0.2, onTappedEditCategory)
            .after(0.3, closeEditView)
            .after(0.15, hideCursor)
            .after(0.5, changeTimeSlot)
    }
    
    private func openEditView(delay: TimeInterval)
    {
        Timer.schedule(withDelay: delay)
        {
            let cell = self.timelineCells[self.editIndex]
            let item = cell.timelineItem!
            self.editView.onEditBegan(
                point: cell.categoryCircle.convert(cell.categoryCircle.center, to: self.timelineView),
                timelineItem: item)
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
        let frame = touchCursor.frame.size
        let w = frame.width
        let h = frame.height
        
        touchCursor.frame = CGRect(x: x - w / 2, y: y - h / 2, width: w, height: h)
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
