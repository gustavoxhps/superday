import UIKit

class CategoryButtonsHandler
{
    private(set) var visibleCells = [CategoryButton]()
    private var reusableCells = Set<CategoryButton>()
    
    private(set) var items : [Category]
    
    init(items: [Category])
    {
        guard !items.isEmpty else { fatalError("empty data array") }
        
        self.items = items
    }
    
    func lastVisibleCell(forward: Bool) -> CategoryButton?
    {
        guard !visibleCells.isEmpty else { return nil }
        
        return forward ? visibleCells.last! : visibleCells.first!
    }
    
    func cell(before cell: CategoryButton?, forward: Bool, cellSize: CGSize) -> CategoryButton
    {
        let nextItemIndex = itemIndex(before: cell?.tag, forward: forward)
        
        let cellToReturn = reusableCells.isEmpty ?
            CategoryButton(frame: CGRect(origin: .zero, size: cellSize)) :
            reusableCells.removeFirst()
        
        cellToReturn.category = items[nextItemIndex]
        cellToReturn.tag = nextItemIndex
        visibleCells.insert(cellToReturn, at: forward ? visibleCells.endIndex : visibleCells.startIndex)
        
        cellToReturn.layer.removeAllAnimations()
        cellToReturn.transform = .identity
        
        return cellToReturn
    }
    
    func remove(cell: CategoryButton)
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
    
    private func itemIndex(before index: Int?, forward: Bool) -> Int
    {
        guard let index = index else { return 0 }
        guard items.count != 1 else { return 0 }
        
        let beforeIndex = index + (forward ? 1 : -1)
        
        return (beforeIndex + items.count) % items.count
    }
}
