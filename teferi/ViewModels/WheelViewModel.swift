import UIKit

class WheelViewModel<V, T> where V: UIButton
{
    typealias attribute = (image: UIImage, color: UIColor)
    
    private(set) var visibleCells = [V]()
    private var reusableCells = Set<V>()
    
    private(set) var items : [T]
    private let attributeSelector : (T) -> attribute
    
    init(items: [T], attributeSelector: @escaping ((T) -> (UIImage, UIColor))) {
        self.items = items
        self.attributeSelector = attributeSelector
    }
    
    private func itemIndex(before index: Int?, clockwise: Bool) -> Int
    {
        guard let index = index else { return 0 }
        
        guard !items.isEmpty else { fatalError("empty data array") }
        
        guard items.count != 1 else { return 0 }
        
        let beforeIndex = index + (clockwise ? 1 : -1)
        
        guard beforeIndex < items.endIndex else { return items.startIndex }
        
        guard beforeIndex >= items.startIndex else { return items.endIndex - 1 }
        
        return beforeIndex
    }
    
    func lastVisibleCell(clockwise: Bool) -> V?
    {
        guard !visibleCells.isEmpty else { return nil }
        
        return clockwise ? visibleCells.last! : visibleCells.first!
    }
    
    func cell(before cell: V?, clockwise: Bool, cellSize: CGSize) -> V
    {
        let nextItemIndex = itemIndex(before: cell?.tag, clockwise: clockwise)
        
        let attributes = attributeSelector(items[nextItemIndex])
        
        guard !reusableCells.isEmpty
            else {
                let cell = cellWithAttributes(cell: V(frame: CGRect(origin: .zero, size: cellSize)),
                                              attributes: attributes)
                cell.tag = nextItemIndex
                cell.layer.cornerRadius = min(cellSize.width, cellSize.height) / 2
                visibleCells.insert(cell, at: clockwise ? visibleCells.endIndex : visibleCells.startIndex)
                return cell
        }
        
        let reusedCell = cellWithAttributes(cell: reusableCells.removeFirst(),
                                            attributes: attributes)
        reusedCell.tag = nextItemIndex
        visibleCells.insert(reusedCell, at: clockwise ? visibleCells.endIndex : visibleCells.startIndex)
        
        return reusedCell
    }
    
    func remove(cell: V)
    {
        let index = visibleCells.index(of: cell)
        visibleCells.remove(at: index!)
        cell.removeFromSuperview()
        reusableCells.insert(cell)
    }
    
    func cleanAll()
    {
        visibleCells.forEach { (cell) in
            cell.removeFromSuperview()
        }
        
        visibleCells.removeAll()
        
        reusableCells.forEach { (cell) in
            cell.removeFromSuperview()
        }
        
        reusableCells.removeAll()
    }
    
    private func cellWithAttributes(cell: V, attributes: attribute) -> V
    {
        cell.backgroundColor = attributes.color
        cell.setImage(attributes.image, for: .normal)
        return cell
    }
}
