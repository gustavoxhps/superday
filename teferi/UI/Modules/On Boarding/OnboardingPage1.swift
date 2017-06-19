import UIKit

class OnboardingPage1 : OnboardingPage
{
    @IBOutlet private weak var textView: UIView!
    @IBOutlet private weak var timelineView: UIView!
    
    private var timelineCells : [TimelineCell]!
    private lazy var timeSlots : [TimeSlot] =
    {
        return [
            self.getTimeSlot(withStartTime: self.getDate(addingHours: 9, andMinutes: 30),
                             endTime: self.getDate(addingHours: 10, andMinutes: 0),
                             category: .leisure),
            
            self.getTimeSlot(withStartTime: self.getDate(addingHours: 10, andMinutes: 0),
                             endTime: self.getDate(addingHours: 10, andMinutes: 55),
                             category: .work)
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
