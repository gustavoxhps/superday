import UIKit

class OnboardingPage1 : OnboardingPage
{
    
    @IBOutlet private weak var textView: UIView!
    @IBOutlet private weak var timelineView: UIView!
    
    private var timelineCells : [TimelineCell]!
    private lazy var timeSlots : [TimeSlot] =
    {
        return [
            self.viewModel.timeSlot(withCategory: .leisure, from: "9:30", to: "10:00"),
            self.viewModel.timeSlot(withCategory: .work, from: "10:00", to: "10:55")
        ]
    }()
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder, nextButtonText: "Next")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        initAnimatedTitleText(textView)
        timelineCells = initAnimatingTimeline(with: timeSlots, in: timelineView)
    }
    
    override func startAnimations()
    {
        animateTitleText(textView, duration: 1, delay: 1)
        animateTimeline(timelineCells, delay: 1.3)
    }
}
