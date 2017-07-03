import UIKit
import RxSwift

class OnboardingPage : UIViewController
{
    internal var viewModel : OnboardingPageViewModel!
    
    //MARK: Public Properties
    var allowPagingSwipe : Bool { return self.nextButtonText != nil }

    private(set) var didAppear = false
    private(set) var nextButtonText : String?
        
    private(set) var onboardingPageViewController : OnboardingViewController!
    
    //MARK: Initializers
    init?(coder aDecoder: NSCoder, nextButtonText: String?)
    {
        super.init(coder: aDecoder)
        
        self.nextButtonText = nextButtonText
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: Public Methods
    
    func inject(viewModel: OnboardingPageViewModel, onboardingPageViewController: OnboardingViewController)
    {
        self.viewModel = viewModel
        self.onboardingPageViewController = onboardingPageViewController
    }
    
    //MARK: Private Methods
    internal func finish()
    {
        DispatchQueue.main.async {
            self.onboardingPageViewController.goToNextPage(forceNext: false)
        }
    }

    internal func startAnimations()
    {
        // override in page
    }

    internal func createTimelineCell(for timeSlot: TimeSlot) -> TimelineCell
    {
        let cell = Bundle.main
            .loadNibNamed("TimelineCell", owner: self, options: nil)?
            .first as! TimelineCell
        
        let timelineItem = viewModel.timelineItem(forTimeslot: timeSlot)
        let duration = timelineItem.durations.reduce(0, +)
        
        cell.bind(toTimelineItem: timelineItem, index: 0, duration: duration)
        return cell
    }

    internal func initAnimatedTitleText(_ view: UIView)
    {
        view.transform = CGAffineTransform(translationX: 100, y: 0)
    }

    internal func animateTitleText(_ view: UIView, duration: TimeInterval, delay: TimeInterval)
    {
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseOut, animations:
            {
                view.transform = CGAffineTransform(translationX: 0, y: 0)
        },
                       completion: nil)
    }
    
    internal func initAnimatingTimeline(with slots: [TimeSlot], in containingView: UIView) -> [TimelineCell]
    {
        
        let cells = createTimelineCells(for: slots)
        
        var previousCell:TimelineCell?
        for cell in cells
        {
            containingView.addSubview(cell)
            
            cell.snp.makeConstraints { make in
                if let previousCell = previousCell
                {
                    make.top.equalTo(previousCell.snp.bottom)
                }
                else {
                    make.top.equalToSuperview()
                }
                make.leading.trailing.equalToSuperview()
            }
            
            cell.transform = CGAffineTransform(translationX: 0, y: 15)
            cell.alpha = 0
            
            previousCell = cell
        }
        
        return cells
    }
    
    internal func animateTimeline(_ cells: [TimelineCell], delay initialDelay: TimeInterval)
    {
        var delay = initialDelay
        
        for cell in cells
        {
            UIView.animate(withDuration: 0.6, delay: delay, options: .curveEaseOut, animations:
                {
                    cell.transform = CGAffineTransform(translationX: 0, y: 0)
                    cell.alpha = 1
            },
                           completion: nil)
            
            delay += 0.2
        }
    }

    private func createTimelineCells(for timeSlots: [TimeSlot]) -> [TimelineCell]
    {
        return timeSlots.map(createTimelineCell)
    }

    
    //MARK: ViewController lifecycle

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        guard !didAppear else { return }
        didAppear = true
        
        startAnimations()
    }
}
