import RxSwift
import RxCocoa
import UIKit
import CoreGraphics

protocol TimelineDelegate: class
{
    func resizeHeader(size:CGFloat)
    func chageShadow(opacity:Float)
}

class TimelineViewController : UIViewController, UITableViewDelegate
{
    // MARK: Public Properties
    var date : Date { return self.viewModel.date }

    // MARK: Private Properties
    private let disposeBag = DisposeBag()
    private let viewModel : TimelineViewModel
    private let presenter : TimelinePresenter
    
    private var tableView : UITableView!
    
    private let cellIdentifier = "timelineCell"
    
    private var willDisplayNewCell:Bool = false
    
    private var emptyStateView: EmptyStateView!
    
    weak var delegate: TimelineDelegate?
    
    // MARK: Initializers
    init(presenter: TimelinePresenter, viewModel: TimelineViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("NSCoder init is not supported for this ViewController")
    }
    
    // MARK: UIViewController lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView = UITableView(frame: view.bounds)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyStateView = EmptyStateView.fromNib()
        view.addSubview(emptyStateView!)
        emptyStateView!.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        emptyStateView?.isHidden = true

        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.register(UINib.init(nibName: "TimelineCell", bundle: Bundle.main), forCellReuseIdentifier: cellIdentifier)
        tableView.contentInset = UIEdgeInsets(top: 34, left: 0, bottom: 0, right: 0)        
        
        viewModel.timeObservable
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: onTimeTick)
            .addDisposableTo(disposeBag)
        
        let itemsObservable = viewModel.timelineItemsObservable
            .asDriver(onErrorJustReturn: [])
            
        itemsObservable
            .drive(tableView.rx.items, curriedArgument: constructCell)
            .addDisposableTo(disposeBag)
        
        itemsObservable
            .drive(onNext: { [unowned self] items in
                self.emptyStateView.isHidden = items.count != 0
                self.handleNewItem(items)
            })
            .addDisposableTo(disposeBag)

        viewModel.presentEditViewObservable
            .subscribe(onNext: startEditOnLastSlot)
            .addDisposableTo(disposeBag)
        
        tableView.rx.setDelegate(self).addDisposableTo(disposeBag)
        tableView.rx.willDisplayCell
            .subscribe(onNext: { [unowned self] (cell, indexPath) in
                guard self.willDisplayNewCell && indexPath.row == self.tableView.numberOfRows(inSection: 0) - 1 else { return }
                
                (cell as! TimelineCell).animateIntro()
                self.willDisplayNewCell = false
            })
            .addDisposableTo(disposeBag)
        
        let currentY = tableView.rx.contentOffset.map({ $0.y })
        let nextY = tableView.rx.contentOffset.skip(1).map({ $0.y })
        
        Observable<(CGFloat, CGFloat)>.zip(currentY, nextY) { ($0, $1) }
            .map { [unowned self] current, next in
                let distance = next - current
                let maxScroll = self.tableView.contentSize.height - self.tableView.frame.height
                
                if next > maxScroll - 10 && distance < 0 { return 0 }
                if next < 10 && distance > 0 { return 0 }
                
                return distance
            }
            .subscribe(onNext: {
                self.delegate?.resizeHeader(size: $0)
            })
            .addDisposableTo(disposeBag)
        
        tableView.rx.contentOffset
            .map{ $0.y }
            .map {
                $0 > 50 ? 1.0 : $0/50
            }
            .subscribe(onNext: { [unowned self] opacity in
                self.delegate?.chageShadow(opacity: Float(opacity))
            })
            .addDisposableTo(disposeBag)
    }

    // MARK: Private Methods

    private func handleNewItem(_ items:[TimelineItem])
    {
        let numberOfItems = tableView.numberOfRows(inSection: 0)
        guard numberOfItems > 0, items.count == numberOfItems + 1 else { return }
        
        willDisplayNewCell = true
        let scrollIndexPath = IndexPath(row: numberOfItems - 1, section: 0)
        tableView.scrollToRow(at: scrollIndexPath, at: .bottom, animated: true)
    }
    
    private func constructCell(forTableView tableView: UITableView, withIndex index: Int, timelineItem:TimelineItem) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: IndexPath(row: index, section: 0)) as! TimelineCell
        
        let duration = viewModel.calculateDuration(ofTimeSlot: timelineItem.timeSlot)
        cell.bind(toTimelineItem: timelineItem, index: index, duration: duration)
        
        if !cell.isSubscribedToClickObservable
        {
            cell.editClickObservable
                .map{ [unowned self] index in
                    return (self.buttonPosition(forCellIndex: index), index)
                }
                .subscribe(onNext: viewModel.notifyEditingBegan)
                .addDisposableTo(disposeBag)
        }
        
        return cell
    }
    
    private func onTimeTick()
    {
        let indexPath = IndexPath(row: tableView.numberOfRows(inSection: 0) - 1, section: 0)
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    private func startEditOnLastSlot()
    {
        let lastRow = tableView.numberOfRows(inSection: 0) - 1
        guard lastRow >= 0 else { return }
        
        let indexPath = IndexPath(row: lastRow, section: 0)
        
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)

        let centerPoint = buttonPosition(forCellIndex: lastRow)

        viewModel.notifyEditingBegan(point: centerPoint, index: lastRow)
    }
    
    private func buttonPosition(forCellIndex index: Int) -> CGPoint
    {
        guard let cell = tableView.cellForRow(at: IndexPath(item: index, section: 0)) as? TimelineCell else {
            return CGPoint.zero
        }
        
        return cell.categoryCircle.convert(cell.categoryCircle.center, to: view)
    }
}
