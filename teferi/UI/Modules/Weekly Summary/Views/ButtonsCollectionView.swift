import UIKit
import RxSwift
import RxCocoa

class ButtonsCollectionView: UICollectionView
{
    @IBOutlet weak var layout: CenterAlignedCollectionViewFlowLayout!

    var disposeBag = DisposeBag()
    
    var toggleCategoryObservable:Observable<Category>!
    
    var categories: Observable<[CategoryButtonModel]>?
    {
        didSet
        {
            bind()
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        setup()
    }
    
    private func setup()
    {
        toggleCategoryObservable = Observable.from([rx.modelSelected(CategoryButtonModel.self), rx.modelDeselected(CategoryButtonModel.self)])
            .merge()
            .map{ $0.category }
        
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 16
        layout.estimatedItemSize = CGSize(width: 100, height: 20)
    }

    private func bind()
    {
        guard let categories = categories else { return }
        
        //Do not remove this line, there's an ugly UIKit bug for plus devices
        self.layoutIfNeeded()

        categories
            .bindTo(self.rx.items(cellIdentifier: "categoryButtonCell", cellType:ButtonCollectionViewCell.self))
            { _, data, cell in
                cell.model = data
            }
            .addDisposableTo(disposeBag)
    }
}
