import RxSwift
import RxCocoa
import UIKit
import CoreGraphics

class TimelineViewController : UIViewController
{
    // MARK: Fields
    private let disposeBag = DisposeBag()
    private let viewModel : TimelineViewModel
    private var tableView : UITableView!
    
    private let cellIdentifier = "timelineCell"
    
    private var willDisplayNewCell:Bool = false
    
    private var emptyStateView:EmptyStateView!
    
    // MARK: Initializers
    init(viewModel: TimelineViewModel)
    {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
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
        
        self.tableView = UITableView(frame: self.view.bounds)
        self.view.addSubview(self.tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.emptyStateView = EmptyStateView.fromNib()
        view.addSubview(emptyStateView!)
        emptyStateView!.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        emptyStateView?.isHidden = true

        
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 100
        self.tableView.separatorStyle = .none
        self.tableView.allowsSelection = false
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.register(UINib.init(nibName: "TimelineCell", bundle: Bundle.main), forCellReuseIdentifier: cellIdentifier)
        
        
        self.viewModel.timeObservable
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: self.onTimeTick)
            .addDisposableTo(self.disposeBag)
        
        let itemsObservable = self.viewModel.timelineItemsObservable
            .asDriver(onErrorJustReturn: [])
            
        itemsObservable
            .drive(self.tableView.rx.items, curriedArgument: constructCell)
            .addDisposableTo(self.disposeBag)
        
        itemsObservable
            .drive(onNext: { [unowned self] items in
                self.emptyStateView.isHidden = items.count != 0
                self.handleNewItem(items)
            })
            .addDisposableTo(self.disposeBag)

        
        self.tableView.rx.willDisplayCell
            .subscribe(onNext: { (cell, indexPath) in
                guard self.willDisplayNewCell && indexPath.row == self.tableView.numberOfRows(inSection: 0) - 1 else { return }
                
                (cell as! TimelineCell).animateIntro()
                self.willDisplayNewCell = false
            })
            .addDisposableTo(self.disposeBag)
    }
    
    private func handleNewItem(_ items:[TimelineItem])
    {
        let numberOfItems = self.tableView.numberOfRows(inSection: 0)
        guard numberOfItems > 0, items.count == numberOfItems + 1 else { return }
        
        self.willDisplayNewCell = true
        let scrollIndexPath = IndexPath(row: numberOfItems - 1, section: 0)
        self.tableView.scrollToRow(at: scrollIndexPath, at: .bottom, animated: true)
    }
    
    private func constructCell(forTableView tableView: UITableView, withIndex index: Int, timelineItem:TimelineItem) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: IndexPath(row: index, section: 0)) as! TimelineCell
        
        let duration = self.viewModel.calculateDuration(ofTimeSlot: timelineItem.timeSlot)
        cell.bind(toTimelineItem: timelineItem, index: index, duration: duration)
        
        if !cell.isSubscribedToClickObservable
        {
            cell.editClickObservable
                .subscribe(onNext: self.viewModel.notifyEditingBegan)
                .addDisposableTo(disposeBag)
        }
        
        return cell
    }
    
    private func onTimeTick()
    {
        let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0) - 1, section: 0)
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func startEditOnLastSlot()
    {
        let lastRow = self.tableView.numberOfRows(inSection: 0) - 1
        guard lastRow >= 0 else { return }
        
        let indexPath = IndexPath(row: lastRow, section: 0)
        
        guard let lastCell = self.tableView.cellForRow(at: indexPath) as? TimelineCell,
            lastCell.window != nil //We need to check if the cell is on screen because multiple view controllers can be loaded at the same time
            else { return }

        let centerPoint = lastCell.categoryCircle.convert(lastCell.categoryCircle.center, to: nil)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        self.viewModel.notifyEditingBegan(point: centerPoint, index: lastRow)
    }
}
