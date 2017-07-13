import RxSwift
import RxCocoa
import UIKit
import CoreGraphics
import RxDataSources

protocol TimelineDelegate: class
{
    func didScroll(oldOffset: CGFloat, newOffset: CGFloat)
}

class TimelineViewController : UIViewController
{
    // MARK: Public Properties
    var date : Date { return self.viewModel.date }

    // MARK: Private Properties
    private let disposeBag = DisposeBag()
    private let viewModel : TimelineViewModel
    private let presenter : TimelinePresenter
    
    private var tableView : TimelineTableView!
    
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
    
    private let dataSource = TimelineDataSource()

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
        
        tableView = TimelineTableView(frame: view.bounds)
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
        tableView.register(UINib.init(nibName: "TimelineCell", bundle: Bundle.main), forCellReuseIdentifier: TimelineCell.cellIdentifier)
        tableView.contentInset = UIEdgeInsets(top: 34, left: 0, bottom: 120, right: 0)
        
        viewModel.timeObservable
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: onTimeTick)
            .addDisposableTo(disposeBag)
        
        dataSource.configureCell = constructCell
        
        viewModel.timelineItemsObservable
            .map({ [TimelineSection(items:$0)] })
            .bindTo(tableView.rx.items(dataSource: dataSource))
            .addDisposableTo(disposeBag)
        
        viewModel.timelineItemsObservable
            .map{$0.count > 0}
            .bindTo(emptyStateView.rx.isHidden)
            .addDisposableTo(disposeBag)

        viewModel.presentEditViewObservable
            .subscribe(onNext: startEditOnLastSlot)
            .addDisposableTo(disposeBag)
        
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
    
    private func constructCell(dataSource: TableViewSectionedDataSource<TimelineSection>, tableView: UITableView, indexPath: IndexPath, item:TimelineItem) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: TimelineCell.cellIdentifier, for: indexPath) as! TimelineCell
        cell.timelineItem = item
        
        cell.editClickObservable
            .map{ [unowned self] item in
                let position = cell.categoryCircle.convert(cell.categoryCircle.center, to: self.view)
                return (position, item)
            }
            .subscribe(onNext: self.viewModel.notifyEditingBegan)
            .addDisposableTo(cell.disposeBag)
        
        cell.collapseClickObservable
            .subscribe(onNext: viewModel.collapseSlots)
            .addDisposableTo(cell.disposeBag)
        
        cell.expandClickObservable
            .subscribe(onNext: viewModel.expandSlots)
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

        viewModel.notifyEditingBegan(point: centerPoint, item: nil)
    }
    
    private func buttonPosition(forCellIndex index: Int) -> CGPoint
    {
        guard let cell = tableView.cellForRow(at: IndexPath(item: index, section: 0)) as? TimelineCell else {
            return CGPoint.zero
        }
        
        return cell.categoryCircle.convert(cell.categoryCircle.center, to: view)
    }
}
