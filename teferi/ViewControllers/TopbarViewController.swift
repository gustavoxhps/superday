import UIKit
import RxSwift
import Foundation

class TopBarViewController : UIViewController
{
    // MARK: Fields
    private var viewModel : TopBarViewModel!
    private let disposeBag = DisposeBag()
    
    private var pagerViewController : PagerViewController!
    private var calendarViewController : CalendarViewController!
    
    @IBOutlet private weak var titleLabel : UILabel!
    @IBOutlet private weak var calendarButton : UIButton!
    @IBOutlet private weak var feedbackButton : UIButton!
    
    func inject(viewModel: TopBarViewModel, pagerViewController: PagerViewController, calendarViewController: CalendarViewController)
    {
        self.viewModel = viewModel
        self.pagerViewController = pagerViewController
        self.calendarViewController = calendarViewController
        
        self.createBindings()
    }
    
    // MARK: UIViewController lifecycle methods
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.calendarButton.setTitle(viewModel.calendarDay, for: .normal)
    }
    
    // MARK: Methods
    private func createBindings()
    {
        self.viewModel
            .dateObservable
            .subscribe(onNext: self.onDateChanged)
            .addDisposableTo(self.disposeBag)
        
        self.calendarButton
            .rx.tap
            .subscribe(onNext: self.onCalendarButtonClick)
            .addDisposableTo(self.disposeBag)
        
        self.feedbackButton
            .rx.tap
            .subscribe(onNext: self.onFeedbackButtonClick)
            .addDisposableTo(self.disposeBag)
    }
    
    private func onCalendarButtonClick()
    {
        if self.calendarViewController.isVisible
        {
            self.calendarViewController.hide()
        }
        else
        {
            self.calendarViewController.show()
        }
    }
    
    // MARK: Calendar Actions
    private func onFeedbackButtonClick()
    {
        self.viewModel.composeFeedback()
    }
    
    private func onDateChanged(date: Date)
    {
        self.titleLabel.text = viewModel.title
    }
}
