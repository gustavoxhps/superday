import UIKit
import JTAppleCalendar
import RxSwift

class CalendarViewController : UIViewController
{
    fileprivate var viewModel : CalendarViewModel!
    private var presenter : CalendarPresenter!
    
    private let calendarCell = "CalendarCell"
    
    @IBOutlet weak private var monthLabel : UILabel!
    @IBOutlet weak fileprivate var leftButton : UIButton!
    @IBOutlet weak fileprivate var rightButton : UIButton!
    @IBOutlet weak fileprivate var dayOfWeekLabels : UIStackView!
    @IBOutlet weak fileprivate var calendarBackgroundView : UIView!
    @IBOutlet weak fileprivate var calendarView : JTAppleCalendarView!
    @IBOutlet weak private var calendarHeightConstraint : NSLayoutConstraint!
    
    private lazy var viewsToAnimate : [UIView] =
    {
        [
            self.calendarView,
            self.monthLabel,
            self.dayOfWeekLabels,
            self.leftButton,
            self.rightButton
        ]
    }()
    
    private var disposeBag = DisposeBag()
    private var calendarCellsShouldAnimate = false
    
    func inject(presenter:CalendarPresenter, viewModel: CalendarViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
                
        //Configures the calendar
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.registerCellViewXib(file: calendarCell)
        calendarView.cellInset = CGPoint(x: 1.5, y: 2)
        calendarView.scrollToDate(viewModel.maxValidDate, animateScroll:false)
        
        leftButton.rx.tap
            .subscribe(onNext: onLeftClick)
            .addDisposableTo(disposeBag)
        
        rightButton.rx.tap
            .subscribe(onNext: onRightClick)
            .addDisposableTo(disposeBag)
        
        viewModel
            .currentVisibleCalendarDateObservable
            .subscribe(onNext: onCurrentCalendarDateChanged)
            .addDisposableTo(disposeBag)
        
        viewModel.dateObservable.skip(1)
            .subscribe(onNext: onCurrentlySelectedDateChanged)
            .addDisposableTo(disposeBag)
        
        calendarView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        show()
    }
    
    func hide()
    {
        DelayedSequence
            .start()
            .then(fadeOverlay(fadeIn: false))
            .then(fadeElements(fadeIn: false))
            .after(0.3, dismiss())
    }

    private func show()
    {        
        calendarCellsShouldAnimate = true
        calendarView.reloadData()
        
        DelayedSequence
            .start()
            .then(fadeOverlay(fadeIn: true))
            .after(0.105, fadeElements(fadeIn: true))
            .then(dissableCalendarCellAnimation())
    }
    
    //MARK: Animations
    private func fadeOverlay(fadeIn: Bool) -> (TimeInterval) -> ()
    {
        let alpha = CGFloat(fadeIn ? 1 : 0)
        return { delay in UIView.animate(withDuration: 0.225, delay: delay) { self.view.alpha = alpha } }
    }
    
    private func fadeElements(fadeIn: Bool) -> (TimeInterval) -> ()
    {
        let yDiff = CGFloat(fadeIn ? 0 : -20)
        
        return { delay in
        
            self.viewsToAnimate.forEach { v in
                v.transform = CGAffineTransform(translationX: 0, y: fadeIn ? -20 : 0)
            }
            
            UIView.animate(withDuration: 0.225, delay: delay)
            {
                self.viewsToAnimate.forEach { v in
                    v.transform = CGAffineTransform(translationX: 0, y: yDiff)
                }
            }
        }
    }
    
    private func dissableCalendarCellAnimation() -> (Double) -> ()
    {
        return { delay in
            Timer.schedule(withDelay: delay)
            {
                self.calendarCellsShouldAnimate = false
            }
        }
    }
    
    private func dismiss() -> (Double) -> ()
    {
        return { [unowned self] delay in
            Timer.schedule(withDelay: delay)
            {
                self.presenter.dismiss()
            }
        }
    }
    
    //MARK: Rx methods
    private func onLeftClick()
    {
        calendarView.scrollToPreviousSegment(true, animateScroll: true, completionHandler: nil)
    }
    
    private func onRightClick()
    {
        calendarView.scrollToNextSegment(true, animateScroll: true, completionHandler: nil)
    }
    
    private func onCurrentCalendarDateChanged(_ date: Date)
    {        
        calendarHeightConstraint.constant = calculateCalendarHeight(forDate: date)
        UIView.animate(withDuration: 0.15) {
            self.view.layoutIfNeeded()
        }
        
        monthLabel.attributedText = getHeaderName(forDate: date)
        
        leftButton.alpha = date.month == viewModel.minValidDate.month ? 0.2 : 1.0
        rightButton.alpha =  date.month == viewModel.maxValidDate.month ? 0.2 : 1.0
    }
    
    private func onCurrentlySelectedDateChanged(_ date: Date)
    {
        calendarView.selectDates([date])
        hide()
    }
    
    private func calculateCalendarHeight(forDate date: Date) -> CGFloat
    {
        let startDay = (date.dayOfWeek + 6) % 7
        let daysInMonth = date.daysInMonth
        var numberOfRows = (startDay + daysInMonth) / 7
        
        if (startDay + daysInMonth) % 7 != 0 { numberOfRows += 1 }
        
        let cellHeight = calendarView.bounds.height / 6
                
        return calendarView.frame.origin.y + cellHeight * CGFloat(numberOfRows)
    }
    
    private func getHeaderName(forDate date: Date) -> NSMutableAttributedString
    {
        let monthName = DateFormatter().monthSymbols[(date.month - 1) % 12]
        let result = NSMutableAttributedString(string: "\(monthName) ",
                                               attributes: [ NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: UIFont.systemFont(ofSize: 14) ])
        
        result.append(NSAttributedString(string: String(date.year),
                                         attributes: [ NSForegroundColorAttributeName: Style.Color.offBlackTransparent, NSFontAttributeName: UIFont.systemFont(ofSize: 14) ]))
        
        return result
    }
    
    fileprivate func update(cell: CalendarCell, toDate date: Date, row: Int, belongsToMonth: Bool)
    {
        guard belongsToMonth else
        {
            cell.reset(allowScrollingToDate: false)
            return
        }
        
        let canScrollToDate = viewModel.canScroll(toDate: date)
        let activities = viewModel.getActivities(forDate: date)
        let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
        
        cell.bind(toDate: date, isSelected: isSelected, allowsScrollingToDate: canScrollToDate, dailyActivity: activities)
        
        guard calendarCellsShouldAnimate else { return }
        
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: -20, y: 0)
        
        UIView.animate(withDuration: 0.225, delay: 0.05 + (Double(row) / 20.0))
        {
            cell.alpha = 1
            cell.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
}

extension CalendarViewController: JTAppleCalendarViewDelegate, JTAppleCalendarViewDataSource
{
    //MARK: JTAppleCalendarDelegate implementation
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters
    {
        let parameters = ConfigurationParameters(startDate: viewModel.minValidDate,
                                                 endDate: viewModel.maxValidDate,
                                                 numberOfRows: 6,
                                                 calendar: nil,
                                                 generateInDates: .forAllMonths,
                                                 generateOutDates: .tillEndOfGrid,
                                                 firstDayOfWeek: .monday)
        return parameters
    }
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplayCell cell: JTAppleDayCellView, date: Date, cellState: CellState)
    {
        guard let calendarCell = cell as? CalendarCell else { return }
        
        update(cell: calendarCell, toDate: date, row: cellState.row(), belongsToMonth: cellState.dateBelongsTo == .thisMonth)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleDayCellView?, cellState: CellState)
    {
        viewModel.selectedDate = date
        calendar.reloadData()
        
        guard let calendarCell = cell as? CalendarCell else { return }
        
        update(cell: calendarCell, toDate: date, row: cellState.row(), belongsToMonth: cellState.dateBelongsTo == .thisMonth)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo)
    {
        guard let startDate = visibleDates.monthDates.first else { return }
        
        viewModel.currentVisibleCalendarDate = startDate
    }
}

extension CalendarViewController: UIGestureRecognizerDelegate
{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
    {
        if let view = touch.view,
            view.isDescendant(of: leftButton) ||
                view.isDescendant(of: rightButton) ||
                view.isDescendant(of: calendarView) ||
                view.isDescendant(of: dayOfWeekLabels) ||
                view.isDescendant(of: calendarBackgroundView)
        {
            return false
        }
        
        hide()
        return true
    }
}
