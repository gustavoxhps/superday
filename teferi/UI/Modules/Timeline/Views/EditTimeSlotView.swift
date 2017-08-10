import UIKit
import RxSwift

class EditTimeSlotView : UIView, TrigonometryHelper, CategoryButtonDelegate
{
    typealias DismissType = (() -> ())
    typealias TimeSlotEdit = (TimelineItem, Category)
    
    // MARK: Public Properties
    var dismissAction : DismissType?
    private(set) lazy var editEndedObservable : Observable<TimeSlotEdit> =
    {
        return self.editEndedSubject.asObservable()
    }()
    
    var isEditing : Bool = false
    {
        didSet
        {
            guard !isEditing else { return }
            
            hide()
        }
    }
    
    // MARK: Private Properties
    // MARK: - Flick components
    private var flickBehavior : UIDynamicItemBehavior!
    private var flickAnimator : UIDynamicAnimator!
    private var previousFlickPoint : CGPoint!
    private var firstFlickPoint : CGPoint!
    private var flickView : UIView!
    
    fileprivate var isFlicking : Bool = false
    {
        didSet
        {
            viewHandler.visibleCells.forEach { (cell) in
                cell.isUserInteractionEnabled = !isFlicking
            }
        }
    }
    
    private var timelineItem : TimelineItem!
    private var selectedItem : Category?
    private let editEndedSubject = PublishSubject<TimeSlotEdit>()
    
    private var currentCategoryBackgroundView : UIView? = nil
    private var currentCategoryImageView : UIImageView? = nil
    private var plusImageView : UIImageView? = nil
    
    private var viewHandler : CategoryButtonsHandler!
    private var mainY : CGFloat!
    private var leftBoundryX : CGFloat!
    private var rightBoundryX : CGFloat!
    private var categoryProvider : CategoryProvider!
    
    private let cellSize : CGSize = CGSize(width: 40.0, height: 40.0)
    private let cellSpacing : CGFloat = 10.0
    private var pageWidth : CGFloat { return cellSize.width + cellSpacing }
    private let animationDuration = TimeInterval(0.225)
    
    // MARK: - Pan gesture components
    private var panGesture : UIPanGestureRecognizer!
    private var previousPanPoint : CGPoint!
    private var firstPanPoint : CGPoint!
    
    // MARK: - Tap gesture components
    private var tapGesture : UITapGestureRecognizer!
    
    //MARK: - Initializers
    init(categoryProvider: CategoryProvider)
    {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        alpha = 0
        self.categoryProvider = categoryProvider
        backgroundColor = UIColor.white.withAlphaComponent(0)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(EditTimeSlotView.handlePan(_:)))
        panGesture.delaysTouchesBegan = false
        addGestureRecognizer(panGesture)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(EditTimeSlotView.handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Public Methods
    func categorySelected(category: Category)
    {
        selectedItem = category
        editEndedSubject.onNext((timelineItem, category))
    }
    
    func onEditBegan(point: CGPoint, timelineItem: TimelineItem)
    {
        guard point.x != 0 && point.y != 0 else { return }
        layoutIfNeeded()
        
        self.timelineItem = timelineItem
        selectedItem = timelineItem.category
        
        alpha = 1.0
        
        let items = categoryProvider.getAll(but: .unknown, timelineItem.category)
        
        viewHandler?.cleanAll()
        viewHandler = CategoryButtonsHandler(items: items)
        
        currentCategoryBackgroundView?.removeFromSuperview()
        currentCategoryBackgroundView = UIView()
        currentCategoryBackgroundView?.backgroundColor = timelineItem.category.color
        currentCategoryBackgroundView?.layer.cornerRadius = 16
        
        addSubview(currentCategoryBackgroundView!)
        currentCategoryBackgroundView?.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.top.equalTo(point.y - 24)
            make.left.equalTo(point.x - 32)
        }
        
        currentCategoryImageView?.removeFromSuperview()
        currentCategoryImageView = newImageView(with: UIImage(asset: timelineItem.category.icon), cornerRadius: 16, contentMode: .scaleAspectFit, basedOn: point)
        currentCategoryImageView?.isHidden = timelineItem.category == .unknown
        
        plusImageView?.removeFromSuperview()
        plusImageView = newImageView(with: UIImage(asset: Category.unknown.icon), cornerRadius: 16, contentMode: .scaleAspectFit, basedOn: point)
        plusImageView?.alpha = selectedItem != .unknown ? 0.0 : 1.0
        
        UIView.animate({
            self.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        }, duration: Constants.editAnimationDuration * 3)
        
        UIView.animate({
            self.plusImageView?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)
            self.plusImageView?.alpha = 1.0
        }, duration: 0.192, withControlPoints: 0.0, 0.0, 0.2, 1)
        
        UIView.animate({
            self.currentCategoryImageView?.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        }, duration: 0.102, withControlPoints: 0.4, 0.0, 1, 1)
        
        show(from: CGPoint(x: point.x - 16, y: point.y - 9))
    }
    
    
    func hide()
    {
        guard viewHandler != nil else { return }
        
        let firstSetpOfAnimation = {
            self.plusImageView!.transform = .identity
            
            if let selectedItem = self.selectedItem, selectedItem != .unknown
            {
                self.plusImageView!.alpha = 0
                self.currentCategoryBackgroundView?.backgroundColor = selectedItem.color
                self.currentCategoryImageView?.image = UIImage(asset: selectedItem.icon)
                self.currentCategoryImageView?.isHidden = false
            }
            
            self.currentCategoryImageView?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
        
        let secondStepOfAnimation = {
            self.currentCategoryImageView!.transform = .identity
        }
        
        let cleanupAfterAnimation = {
            self.plusImageView!.removeFromSuperview()
            self.currentCategoryImageView?.removeFromSuperview()
            self.currentCategoryBackgroundView!.removeFromSuperview()
        }
        
        UIView.animate(firstSetpOfAnimation, duration: 0.192, withControlPoints: 0.0, 0.0, 0.2, 1) {
            UIView.animate(secondStepOfAnimation, duration: 0.09, withControlPoints: 0.0, 0.0, 0.2, 1, completion: cleanupAfterAnimation)
        }
        
        UIView.animate({
            self.backgroundColor = UIColor.white.withAlphaComponent(0)
        }, duration: animationDuration, options: [.curveLinear])
        
        var animationSequence = DelayedSequence.start()
        
        let delay = TimeInterval(0.02)
        let cellsToAnimate = viewHandler.visibleCells.filter({ $0.frame.intersects(bounds) }).reversed()
        
        for cell in cellsToAnimate
        {
            cell.layer.removeAllAnimations()
            animationSequence = animationSequence.after(delay, animateCell(cell, presenting: false))
        }
        
        animationSequence.after(animationDuration, cleanupAfterHide())
    }
    
    //for hacky onboarding animations
    func getIcon(forCategory category: Category) -> UIImageView?
    {
        guard let cell = viewHandler.visibleCells.first(where: { $0.category == category }) else { return nil }
        return UIImageView(frame: cell.frame)
    }

    // MARK: Private Methods
    @objc private func handleTap(_ sender: UITapGestureRecognizer)
    {
        resetFlick()
        panGesture.isEnabled = false
        dismissAction?()
    }
    
    // MARK: - Pan gesture logic
    @objc private func handlePan(_ sender: UIPanGestureRecognizer)
    {
        resetFlick()
        
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
            
            isFlicking = false
            
            let velocity = sender.velocity(in: self)
            
            if shouldFlick(for: velocity)
            {
                flick(with: velocity, from: previousPanPoint!)
            }
            else
            {
                snapCellsToCorrrectPosition()
            }
            
            previousPanPoint = nil
            
        default:
            break
        }
    }
    
    // MARK: - Movement logic
    private func handle(movement: CGFloat)
    {
        guard movement != 0 else { return }
        
        let cells = viewHandler.visibleCells
        
        guard cells.count > 0 else { return }        
        
        let isMovingForward = movement < 0

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
            newCell.delegate = self
            newCell.center = CGPoint(x: lastCellBasedOnDirection.center.x + pageWidth * (isMovingForward ? 1 : -1), y: mainY)
            
            applyScaleTransformIfNeeded(at: newCell)
            
            addSubview(newCell)
            
            lastCellBasedOnDirection = newCell
        }
    }
    
    private func applyScaleTransformIfNeeded(at cell: CategoryButton, customX: CGFloat? = nil)
    {
        let tempTransform = cell.transform
        cell.transform = .identity
        let distanceOutOfLeftBound = cellSize.width - (leftBoundryX - (customX ?? cell.frame.minX))
        cell.transform = tempTransform
        
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
    
    // MARK: - Flick logic
    
    private func flick(with velocity: CGPoint, from point: CGPoint)
    {
        resetFlick()
        
        flickAnimator = UIDynamicAnimator(referenceView: self)
        flickAnimator.delegate = self
        
        let flickViewCenter = point
        firstFlickPoint = flickViewCenter
        flickView = UIView(frame: CGRect(origin: CGPoint(x: flickViewCenter.x - cellSize.width / 2, y: flickViewCenter.y - cellSize.height / 2), size: cellSize))
        flickView.isUserInteractionEnabled = false
        flickView.isHidden = true
        addSubview(flickView)
        
        flickBehavior = UIDynamicItemBehavior(items: [flickView])
        flickBehavior.addLinearVelocity(velocity, for: flickView)
        flickBehavior.allowsRotation = false
        flickBehavior.resistance = 5
        flickBehavior.elasticity = 1
        flickBehavior.density = 1.5
        flickBehavior.action = flickBehaviorAction
        flickAnimator.addBehavior(flickBehavior)
    }
    
    private func resetFlick()
    {
        flickAnimator = nil
        flickBehavior = nil
        flickView = nil
        previousFlickPoint = nil
        firstFlickPoint = nil
    }
    
    private func flickBehaviorAction()
    {
        guard let _ = previousFlickPoint
        else
        {
            previousFlickPoint = flickView.center
            return
        }
        
        if distance(a: previousFlickPoint, b: flickView.center) == 0
        {
            isFlicking = false
            resetFlick()
            snapCellsToCorrrectPosition()
            return
        }
        
        handle(movement: flickView.center.x - previousFlickPoint.x)
        
        previousFlickPoint = flickView.center
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        return alpha > 0
    }
    
    private func show(from point: CGPoint)
    {
        panGesture.isEnabled = true
        
        mainY = point.y
        leftBoundryX = point.x + 32 / 2 + cellSpacing
        rightBoundryX = bounds.width
        
        var animationSequence = DelayedSequence.start()
        
        let delay = TimeInterval(0.04)
        var previousCell : CategoryButton?
        var index = 0
        
        while index != 0 ? bounds.contains(previousCell!.frame) : true {
            let cell = viewHandler.cell(before: previousCell, forward: true, cellSize: cellSize)
            cell.delegate = self
            cell.center = CGPoint(x: leftBoundryX + pageWidth * CGFloat(index) + cellSize.width / 2, y: mainY)
            cell.isHidden = true
            
            addSubview(cell)
            
            animationSequence = animationSequence.after(delay, animateCell(cell, presenting: true))
            
            previousCell = cell
            index += 1
        }
    }
    
    private func cleanupAfterHide() -> (TimeInterval) -> ()
    {
        return { delay in
            Timer.schedule(withDelay: delay)
            {
                self.resetFlick()
                self.viewHandler.cleanAll()
                self.alpha = 0
                self.selectedItem = nil
            }
        }
    }
    
    // MARK: - Animation
    private func animateCell(_ cell: CategoryButton, presenting: Bool) -> (TimeInterval) -> ()
    {
        return { delay in
            Timer.schedule(withDelay: delay)
            {
                if presenting {
                    cell.show()
                } else {
                    cell.hide()
                }                
            }
        }
    }
    
    private func snapCellsToCorrrectPosition()
    {
        let cells = viewHandler.visibleCells
        
        guard let firstCell = cells.first else { return }
        
        let tempTransform = firstCell.transform
        firstCell.transform = .identity
        
        let distanceBasedOnPageWidth = firstCell.center.x - leftBoundryX + pageWidth / 2
        let offset = abs(pageWidth - abs(distanceBasedOnPageWidth)) < pageWidth / 2 ?
            (distanceBasedOnPageWidth > 0 ? 1 : -1) * pageWidth - distanceBasedOnPageWidth :
            -distanceBasedOnPageWidth
        
        firstCell.transform = tempTransform
        
        let animationDuration = 0.334
        
        UIView.animate({
            cells.forEach { (cell) in
                cell.center = CGPoint(x: cell.center.x + offset, y: self.mainY)
                if !self.isInAllowedRange(cell)
                {
                    self.viewHandler.remove(cell: cell)
                }
            }
            self.applyScaleTransformIfNeeded(at: cells.first!, customX: offset < 0 ? self.leftBoundryX : self.leftBoundryX + self.pageWidth)
        }, duration: TimeInterval(animationDuration),
           options: [.curveEaseInOut])
    }
    
    // MARK: - Conveniece methods
    private func newImageView(with image: UIImage, cornerRadius: CGFloat, contentMode: UIViewContentMode, basedOn point: CGPoint) -> UIImageView
    {
        let imageView = UIImageView(image: image)
        imageView.layer.cornerRadius = cornerRadius
        imageView.contentMode = contentMode
        
        addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(15)
            make.top.equalTo(point.y - 15.4)
            make.left.equalTo(point.x - 23.4)
        }
        
        return imageView
    }
    
    // MARK: - Math functions
    private func isInAllowedRange(_ cell: CategoryButton) -> Bool
    {
        return (cell.frame.minX > leftBoundryX && cell.frame.minX < rightBoundryX) || (cell.frame.maxX > leftBoundryX && cell.frame.maxX < rightBoundryX)
    }
    
    private func shouldFlick(for velocity: CGPoint) -> Bool
    {
        return abs( velocity.x ) > 200
    }
}

extension EditTimeSlotView: UIDynamicAnimatorDelegate
{
    // MARK: - UIDynamicAnimatorDelegate
    
    func dynamicAnimatorWillResume(_ animator: UIDynamicAnimator)
    {
        isFlicking = true
    }
    
    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator)
    {
        isFlicking = false
    }
}
