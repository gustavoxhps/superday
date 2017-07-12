import RxSwift
import RxCocoa
import UIKit
import CoreGraphics

protocol TimelineDelegate: class
{
    func didScroll(oldOffset: CGFloat, newOffset: CGFloat)
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
    {
        didSet
        {
            let topInset = tableView.contentInset.top
            let offset = tableView.contentOffset.y
            delegate?.didScroll(oldOffset: offset + topInset, newOffset: offset + topInset)
        }
    }
    
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

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.register(UINib.init(nibName: "TimelineCell", bundle: Bundle.main), forCellReuseIdentifier: cellIdentifier)
        tableView.contentInset = UIEdgeInsets(top: 34, left: 0, bottom: 120, right: 0)
        
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
        
        let oldOffset = tableView.rx.contentOffset.map({ $0.y })
        let newOffset = tableView.rx.contentOffset.skip(1).map({ $0.y })

        Observable<(CGFloat, CGFloat)>.zip(oldOffset, newOffset)
        { [unowned self] old, new -> (CGFloat, CGFloat) in
            // This closure prevents the header to change height when the scroll is bouncing
            
            let maxScroll = self.tableView.contentSize.height - self.tableView.frame.height + self.tableView.contentInset.bottom
            let minScroll = -self.tableView.contentInset.top
            
            if new < minScroll || old < minScroll { return (old, old) }
            if new > maxScroll || old > maxScroll { return (old, old) }
            
            return (old, new)
        }
        .subscribe(onNext: { [unowned self] (old, new) in
            let topInset = self.tableView.contentInset.top
            self.delegate?.didScroll(oldOffset: old + topInset, newOffset: new + topInset)
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
        cell.timelineItem = timelineItem
        
        cell.editClickObservable
            .map{ [unowned self] in
                return (self.buttonPosition(forCellIndex: index), index)
            }
            .subscribe(onNext: viewModel.notifyEditingBegan)
            .addDisposableTo(cell.disposeBag)
        
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
