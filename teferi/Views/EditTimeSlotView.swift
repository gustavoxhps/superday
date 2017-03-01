import UIKit

class EditTimeSlotView : UIView, TrigonometryHelper
{
    typealias ViewType = UIButton
    typealias DismissType = (() -> ())
    
    //MARK: Properties
    private var onEditEnded : ((TimeSlot, Category) -> Void)!
    private var timeSlot : TimeSlot!
    private var selectedItem : Category!
    
    private var currentCategoryBackgroundView : UIView? = nil
    private var currentCategoryImageView : UIImageView? = nil
    private var plusImageView : UIImageView? = nil
    
    private var viewHandler : ItemViewHandler<ViewType, Category>!
    private var mainY : CGFloat!
    private var leftBoundryX : CGFloat!
    private var rightBoundryX : CGFloat!
    
    private let cellSize : CGSize = CGSize(width: 40.0, height: 40.0)
    private let cellSpacing : CGFloat = 10.0
    private var pageWidth : CGFloat { return cellSize.width + cellSpacing }
    private let animationDuration = TimeInterval(0.225)
    
    
    var dismissAction : DismissType?
    
    // MARK: - Pan gesture components
    private var panGesture : UIPanGestureRecognizer!
    private var previousPanPoint : CGPoint!
    private var firstPanPoint : CGPoint!
    
    // MARK: - Tap gesture components
    private var tapGesture : UITapGestureRecognizer!
    
    var isEditing : Bool = false
    {
        didSet
        {
            guard !isEditing else { return }

            hide()
        }
    }
    
    //MARK: Initializers
    init(editEndedCallback: @escaping (TimeSlot, Category) -> Void)
    {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        self.alpha = 0
        self.onEditEnded = editEndedCallback
        self.backgroundColor = Color.white.withAlphaComponent(0)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        panGesture.delaysTouchesBegan = false
        addGestureRecognizer(panGesture)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - SelectionHandling
    @objc private func didSelectCell(_ sender: ViewType)
    {
        selectedItem = viewHandler.items[sender.tag]
        onEditEnded(timeSlot, selectedItem!)
    }
    
    // MARK: - Tap gesture logic
    @objc private func handleTap(_ sender: UITapGestureRecognizer)
    {
        panGesture.isEnabled = false
        dismissAction?()
    }
    
    // MARK: - Pan gesture logic
    @objc private func handlePan(_ sender: UIPanGestureRecognizer)
    {
        let panPoint: CGPoint = sender.location(in: self)
        
        switch sender.state {
        case .began:
            
            if abs(panPoint.y - mainY) > cellSize.height * 1.5
            {
                dismissAction?()
                sender.isEnabled = false
                return
            }
            
            previousPanPoint = panPoint
            firstPanPoint = panPoint
            
        case .changed:
            
            handle(movement: panPoint.x - previousPanPoint.x)
            
            previousPanPoint = panPoint
            
        case .ended:
            
            previousPanPoint = nil
            
            let distanceBasedOnPageWidth = CGFloat(fmodf(Float(panPoint.x - firstPanPoint.x), Float(pageWidth)))

            abs(pageWidth - abs(distanceBasedOnPageWidth)) < pageWidth / 2 ?
                snapCellsToCorrrectPosition(with: (distanceBasedOnPageWidth > 0 ? 1 : -1) * pageWidth - distanceBasedOnPageWidth) :
                snapCellsToCorrrectPosition(with: -distanceBasedOnPageWidth)
            
        default:
            break
        }
    }
    
    // MARK: - Movement logic
    private func handle(movement: CGFloat)
    {
        guard movement != 0 else { return }
        
        let isMovingForward = movement < 0
        
        let cells = viewHandler.visibleCells

        let pointToBaseMovement = isMovingForward ? CGPoint(x: cells.first!.center.x + movement, y: mainY) : CGPoint(x: cells[1].center.x + movement - pageWidth, y: mainY)

        for (index, cell) in cells.enumerated()
        {
            cell.center = CGPoint(x: pointToBaseMovement.x + pageWidth * CGFloat(index), y: pointToBaseMovement.y)

            if !isInAllowedRange(cell)
            {
                viewHandler.remove(cell: cell)
            }
        }
        
        applyScaleTransformIfNeeded(at: cells.first!)
        
        guard var lastCellBasedOnDirection = viewHandler.lastVisibleCell(forward: isMovingForward) else { return }
        
        while isMovingForward ? lastCellBasedOnDirection.frame.minX + cellSize.width < rightBoundryX : lastCellBasedOnDirection.frame.minX - cellSpacing > leftBoundryX
        {
            let newCell = viewHandler.cell(before: lastCellBasedOnDirection, forward: isMovingForward, cellSize: cellSize)
            newCell.addTarget(self, action: #selector(self.didSelectCell(_:)), for: .touchUpInside)
            newCell.center = CGPoint(x: lastCellBasedOnDirection.center.x + pageWidth * (isMovingForward ? 1 : -1), y: mainY)
            
            applyScaleTransformIfNeeded(at: newCell)
            
            addSubview(newCell)
            
            lastCellBasedOnDirection = newCell
        }
    }
    
    private func applyScaleTransformIfNeeded(at cell: ViewType, customX: CGFloat? = nil)
    {
        cell.transform = .identity
        let distanceOutOfLeftBound = cellSize.width - (leftBoundryX - (customX ?? cell.frame.minX))
        
        guard distanceOutOfLeftBound < cellSize.width
        else
        {
            cell.transform = .identity
            return
        }
        
        let scaleFactor = abs(distanceOutOfLeftBound / cellSize.width)
        
        let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        let positionTransform = CGAffineTransform(translationX: cellSize.width / 2 - scaleFactor * cellSize.width / 2, y: 0)
        
        cell.transform = scaleTransform.concatenating(positionTransform)
    }
    
    //MARK: - Methods
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        return self.alpha > 0
    }
    
    func onEditBegan(point: CGPoint, timeSlot: TimeSlot)
    {
        guard point.x != 0 && point.y != 0 else { return }
        setNeedsLayout()
        
        self.timeSlot = timeSlot
        self.selectedItem = timeSlot.category
        
        self.alpha = 1.0
        
        let items = Category.all.filter { $0 != .unknown && $0 != timeSlot.category }
        
        viewHandler?.cleanAll()
        viewHandler = ItemViewHandler<ViewType, Category>(items: items, attributeSelector: ({ ($0.icon.image, $0.color) }))
        
        currentCategoryBackgroundView = UIView()
        currentCategoryBackgroundView?.backgroundColor = timeSlot.category.color
        currentCategoryBackgroundView?.layer.cornerRadius = 16
        addSubviewWithConstraints(currentCategoryBackgroundView!, basedOn: point)
        
        currentCategoryImageView = newImageView(with: UIImage(asset: timeSlot.category.icon), cornerRadius: 16, contentMode: .scaleAspectFit, basedOn: point)
        currentCategoryImageView?.isHidden = timeSlot.category == .unknown

        plusImageView = newImageView(with: UIImage(asset: Category.unknown.icon), cornerRadius: 16, contentMode: .center, basedOn: point)
        plusImageView?.alpha = self.selectedItem != .unknown ? 0.0 : 1.0
        
        
        UIView.animate(withDuration: Constants.editAnimationDuration * 3)
        {
            self.backgroundColor = Color.white.withAlphaComponent(0.6)
        }
        
        animate({ 
            UIView.animate(withDuration: 0.192) {
                self.plusImageView?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)
                self.plusImageView?.alpha = 1.0
            }
        }, withControlPoints: 0.0, 0.0, 0.2, 1)
        
        animate({
            UIView.animate(withDuration: 0.102) {
                self.currentCategoryImageView?.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }
        }, withControlPoints: 0.4, 0.0, 1, 1)
        
        
        show(from: CGPoint(x: point.x - 16, y: point.y - 9))
    }
    
    private func animate(_ closure: ()->(), withControlPoints c1x: Float, _ c1y: Float, _ c2x: Float, _ c2y: Float)
    {
        let timingFunction = CAMediaTimingFunction(controlPoints: c1x, c1y, c2x, c2y)
        
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(timingFunction)
        
        closure()
        
        CATransaction.commit()
    }
    
    private func newImageView(with image: UIImage, cornerRadius: CGFloat, contentMode: UIViewContentMode, basedOn point: CGPoint) -> UIImageView
    {
        let imageView = UIImageView(image: image)
        imageView.layer.cornerRadius = cornerRadius
        imageView.contentMode = contentMode
        
        self.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(15.4)
            make.top.equalTo(point.y - 15.6)
            make.left.equalTo(point.x - 23.6)
        }
        
        return imageView
    }
    
    private func addSubviewWithConstraints(_ viewToAdd: UIView, basedOn point: CGPoint)
    {
        self.addSubview(viewToAdd)
        
        viewToAdd.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.top.equalTo(point.y - 24)
            make.left.equalTo(point.x - 32)
        }
    }
    
    private func show(from point: CGPoint)
    {
        self.panGesture.isEnabled = true
        
        mainY = point.y
        leftBoundryX = point.x + 32 / 2 + cellSpacing
        rightBoundryX = bounds.width
        
        var animationSequence = DelayedSequence.start()
        
        let delay = TimeInterval(0.04)
        var previousCell : ViewType?
        var index = 0
        
        while index != 0 ? bounds.contains(previousCell!.frame) : true {
            let cell = viewHandler.cell(before: previousCell, forward: true, cellSize: cellSize)
            cell.addTarget(self, action: #selector(self.didSelectCell(_:)), for: .touchUpInside)
            cell.center = CGPoint(x: leftBoundryX + pageWidth * CGFloat(index) + cellSize.width / 2, y: mainY)
            cell.isHidden = true
            
            addSubview(cell)
            
            animationSequence = animationSequence.after(delay, animate(cell, presenting: true))
            
            previousCell = cell
            index += 1
        }
    }
    
    func hide()
    {
        guard viewHandler != nil else { return }
        
        animate({
            UIView.animate(withDuration: 0.192, animations: {
                self.plusImageView!.transform = .identity
                
                if self.selectedItem != .unknown
                {
                    self.plusImageView!.alpha = 0
                    self.currentCategoryBackgroundView?.backgroundColor = self.selectedItem.color
                    self.currentCategoryImageView?.image = UIImage(asset: self.selectedItem.icon)
                    self.currentCategoryImageView?.isHidden = false
                }
                self.currentCategoryImageView?.transform = .identity
            }) { (_) in
                self.plusImageView!.removeFromSuperview()
                self.currentCategoryImageView?.removeFromSuperview()
                self.currentCategoryBackgroundView!.removeFromSuperview()
            }
        }, withControlPoints: 0.0, 0.0, 0.2, 1)
        
        
        UIView.animate(withDuration: animationDuration ,
                       delay: 0.0,
                       options: .curveLinear,
                       animations:  {
                        self.backgroundColor = Color.white.withAlphaComponent(0)
        })
        
        var animationSequence = DelayedSequence.start()
        
        let delay = TimeInterval(0.02)
        let cellsToAnimate = viewHandler.visibleCells.filter({ $0.frame.intersects(bounds) }).reversed()
        
        for cell in cellsToAnimate
        {
            animationSequence = animationSequence.after(delay, animate(cell, presenting: false))
        }
        
        animationSequence.after(animationDuration, cleanupAfterHide())
    }
    
    private func cleanupAfterHide() -> (TimeInterval) -> ()
    {
        return { delay in
            Timer.schedule(withDelay: delay)
            {
                self.viewHandler.cleanAll()
                self.alpha = 0
                self.selectedItem = nil
            }
        }
    }
    
    // MARK: - Animation
    private func animate(_ cell: ViewType, presenting: Bool) -> (TimeInterval) -> ()
    {
        return { delay in
            Timer.schedule(withDelay: delay)
            {
                let scaleTransform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                
                cell.transform = presenting ?
                    scaleTransform :
                    .identity
                
                cell.isHidden = false
                
                let timingFunction = presenting ?
                    CAMediaTimingFunction(controlPoints: 0.23, 1, 0.32, 1) :
                    CAMediaTimingFunction(controlPoints: 0.175, 0.885, 0.32, 1)
                
                CATransaction.begin()
                CATransaction.setAnimationTimingFunction(timingFunction)
                
                UIView.animate(withDuration: self.animationDuration, animations:
                    {
                        cell.transform = presenting ?
                            .identity :
                            scaleTransform
                })
                
                CATransaction.commit()
            }
        }
    }
    
    private func snapCellsToCorrrectPosition(with offset: CGFloat)
    {
        let cells = viewHandler.visibleCells
        
        let animationDuration = 0.334
        
        UIView.animate(withDuration: TimeInterval(animationDuration),
                       delay: 0.0,
                       options: .curveEaseInOut,
                       animations:
            {
                cells.forEach { (cell) in
                    cell.center = CGPoint(x: cell.center.x + offset, y: self.mainY)
                    if !self.isInAllowedRange(cell)
                    {
                        self.viewHandler.remove(cell: cell)
                    }
                }
                self.applyScaleTransformIfNeeded(at: cells.first!, customX: offset < 0 ? self.leftBoundryX : self.leftBoundryX + self.pageWidth)
            },
                       completion: nil
        )
    }
    
    // MARK: - for hacky onboarding animations
    func getIcon(forCategory category: Category) -> UIImageView?
    {
        let color = category.color
        let cell = viewHandler.visibleCells.first(where: { (b) in b.backgroundColor == color })
        return UIImageView(frame: cell!.frame)
    }
    
    // MARK: - Math functions
    private func isInAllowedRange(_ cell: ViewType) -> Bool
    {
        return (cell.frame.minX > leftBoundryX && cell.frame.minX < rightBoundryX) || (cell.frame.maxX > leftBoundryX && cell.frame.maxX < rightBoundryX)
    }
}
