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
        self.initAnimatedTitleText(self.textView)
        self.timelineCells = self.initAnimatingTimeline(with: self.timeSlots, in: self.timelineView)
    }
    
    override func startAnimations()
    {
        self.animateTitleText(self.textView, duration: 1, delay: 1)
        self.animateTimeline(self.timelineCells, delay: 1.3)
    }
}
