import RxSwift
import RxCocoa
import UIKit
import CoreGraphics

class TimelineViewController : UITableViewController
{
    // MARK: Fields
    private static let baseCellHeight = 40
    
    private let disposeBag = DisposeBag()
    private let viewModel : TimelineViewModel
    
    private var editingIndex = -1
    private let cellIdentifier = "timelineCell"
    private let emptyCellIdentifier = "emptyStateView"
    
    private var willDisplayNewCell:Bool = false
    
    private lazy var footerCell : UITableViewCell = { return UITableViewCell(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 120)) }()
    
    // MARK: Initializers
    init(viewModel: TimelineViewModel)
    {
        self.viewModel = viewModel
        
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("NSCoder init is not supported for this ViewController")
    }
    
    // MARK: Properties
    var date : Date { return self.viewModel.date }
    
    // MARK: UIViewController lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tableView.separatorStyle = .none
        self.tableView.allowsSelection = false
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.register(UINib.init(nibName: "TimelineCell", bundle: Bundle.main), forCellReuseIdentifier: cellIdentifier)
        self.tableView.register(UINib.init(nibName: "EmptyStateView", bundle: Bundle.main), forCellReuseIdentifier: emptyCellIdentifier)
        
        self.viewModel
            .timeObservable
            .subscribe(onNext: self.onTimeTick)
            .addDisposableTo(self.disposeBag)
        
        self.viewModel
            .timeSlotCreatedObservable
            .subscribe(onNext: self.onTimeSlotCreated)
            .addDisposableTo(self.disposeBag)
        
        self.viewModel
            .refreshScreenObservable
            .subscribe(onNext: self.tableView.reloadData)
            .addDisposableTo(self.disposeBag)
        
        self.viewModel
            .isEditingObservable
            .subscribe(onNext: self.onIsEditing)
            .addDisposableTo(self.disposeBag)
        
        self.viewModel
            .editViewObservable
            .subscribe(onNext: self.onEditView)
            .addDisposableTo(self.disposeBag)
    }
    
    private func onTimeSlotCreated(atIndex index: Int)
    {
        self.willDisplayNewCell = true

        let numberOfItems = self.viewModel.timelineItems.count
                
        self.tableView.insertRows(at: [IndexPath(row: numberOfItems - 1, section: 0)], with: .none)
        
        if numberOfItems > 1
        {
            self.tableView.reloadRows(at: [IndexPath(row: numberOfItems - 2, section: 0)], with: .none)
        }
        
        let scrollIndexPath = IndexPath(row: numberOfItems, section: 0)
        self.tableView.scrollToRow(at: scrollIndexPath, at: .bottom, animated: true)
    }
    
    private func onIsEditing(isEditing: Bool)
    {
        self.tableView.isEditing = isEditing
        self.tableView.isScrollEnabled = !isEditing
        
        if self.tableView.isEditing || self.editingIndex == -1 { return }
        
        let indexPath = IndexPath(row: self.editingIndex, section: 0)
        self.tableView.reloadRows(at: [ indexPath ], with: .fade)
        self.editingIndex = -1
    }
    
    private func onTimeTick(time: Int)
    {
        guard !tableView.isEditing else { return }
        
        let indexPath = IndexPath(row: self.viewModel.timelineItems.count - 1, section: 0)
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    private func onEditView(_ index: Int)
    {
        DispatchQueue.main.async
        {
            let scrollIndexPath = IndexPath(row: index + 1, section: 0)
            let lastCellIndexPath = IndexPath(row: index, section: 0)

            self.tableView.scrollToRow(at: scrollIndexPath, at: .bottom, animated: false)
        
            let lastCell = self.tableView(self.tableView, cellForRowAt: lastCellIndexPath) as! TimelineCell
            let centerPoint = lastCell.categoryCircle.convert(lastCell.categoryCircle.center, to: nil)
        
            //We need to check if the cell is on screen because multiple view controllers can be loaded at the same time
            guard lastCell.window != nil else { return }
            
            self.onCategoryTapped(point: centerPoint, index: index)
        }
    }
    
    private func onCategoryTapped(point: CGPoint, index: Int)
    {
        self.editingIndex = index
        self.viewModel.notifyEditingBegan(point: point, index: index)
    }
    
    // MARK: UITableViewDataSource methods
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle
    {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.viewModel.timelineItems.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard self.viewModel.timelineItems.count > 0 else
        {
            return self.tableView.dequeueReusableCell(withIdentifier: emptyCellIdentifier, for: indexPath);
        }
        
        let index = indexPath.row
        if index == self.viewModel.timelineItems.count { return footerCell }
        
        let timelineItem = self.viewModel.timelineItems[index]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! TimelineCell;
        
        let duration = self.viewModel.calculateDuration(ofTimeSlot: timelineItem.timeSlot)
        cell.bind(toTimelineItem: timelineItem, index: index, duration: duration)
        
        if !cell.isSubscribedToClickObservable
        {
            cell.editClickObservable
                .subscribe(onNext: onCategoryTapped)
                .addDisposableTo(disposeBag)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        guard self.viewModel.timelineItems.count > 0 else
        {
            return self.view.frame.height
        }
        
        let index = indexPath.item
        if index == self.viewModel.timelineItems.count { return 120 }
        
        let timelineItem = self.viewModel.timelineItems[index]
        let timeSlot = timelineItem.timeSlot
        let isRunning = timeSlot.endTime == nil
        
        let duration = self.viewModel.calculateDuration(ofTimeSlot: timeSlot)
        return TimelineViewController.timelineCellHeight(duration: duration, isRunning: isRunning)
    }
    
    static func timelineCellHeight(duration : TimeInterval, isRunning : Bool) -> CGFloat
    {
        let interval = Int(duration)
        let hours = (interval / 3600)
        let minutes = (interval / 60) % 60
        let height = baseCellHeight
            + Constants.minLineSize * (1 + (minutes / 15) + (hours * 4))
            + (isRunning ? 24 : 0)
        
        return CGFloat(height)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard self.willDisplayNewCell && indexPath.row == self.viewModel.timelineItems.count - 1 else { return }
        
        (cell as! TimelineCell).animateIntro()
        self.willDisplayNewCell = false
    }
}
