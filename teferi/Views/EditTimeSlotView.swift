import UIKit
import RxSwift

class EditTimeSlotView : UIView, TrigonometryHelper, UIDynamicAnimatorDelegate
{
    typealias ViewType = UIButton
    typealias DismissType = (() -> ())
    typealias TimeSlotEdit = (TimeSlot, Category)
    
    // MARK: Fields
    // MARK: - Flick components
    private var flickBehavior : UIDynamicItemBehavior!
    private var flickAnimator : UIDynamicAnimator!
    private var previousFlickPoint : CGPoint!
    private var firstFlickPoint : CGPoint!
    private var flickView : UIView!
    
    private var isFlicking : Bool = false
    {
        didSet
        {
            viewHandler.visibleCells.forEach { (cell) in
                cell.isUserInteractionEnabled = !isFlicking
            }
        }
    }
    
    private var timeSlot : TimeSlot!
    private var selectedItem : Category?
    private let editEndedSubject = PublishSubject<TimeSlotEdit>()
    
    private var currentCategoryBackgroundView : UIView? = nil
    private var currentCategoryImageView : UIImageView? = nil
    private var plusImageView : UIImageView? = nil
    
    private var viewHandler : ItemViewHandler<ViewType, Category>!
    private var mainY : CGFloat!
    private var leftBoundryX : CGFloat!
    private var rightBoundryX : CGFloat!
    private var categoryProvider : CategoryProvider!
    
    private let cellSize : CGSize = CGSize(width: 40.0, height: 40.0)
    private let cellSpacing : CGFloat = 10.0
    private var pageWidth : CGFloat { return cellSize.width + cellSpacing }
    private let animationDuration = TimeInterval(0.225)
    
    // MARK: Properties
    var dismissAction : DismissType?
    private(set) lazy var editEndedObservable : Observable<TimeSlotEdit> =
    {
        return self.editEndedSubject.asObservable()
    }()
    
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
    
    //MARK: - Initializers
    init(categoryProvider: CategoryProvider)
    {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        self.alpha = 0
        self.categoryProvider = categoryProvider
        self.backgroundColor = UIColor.white.withAlphaComponent(0)
        
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
        editEndedSubject.onNext((timeSlot, selectedItem!))
    }
    
    // MARK: - Tap gesture logic
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
    
    func flickBehaviorAction()
    {
        guard let _ = self.previousFlickPoint
        else
        {
            self.previousFlickPoint = flickView.center
            return
        }
        
        if distance(a: self.previousFlickPoint, b: flickView.center) == 0
        {
            isFlicking = false
            resetFlick()
            snapCellsToCorrrectPosition()
            return
        }
        
        handle(movement: flickView.center.x - previousFlickPoint.x)
        
        self.previousFlickPoint = flickView.center
    }
    
    // MARK: - UIDynamicAnimatorDelegate
    
    func dynamicAnimatorWillResume(_ animator: UIDynamicAnimator)
    {
        isFlicking = true
    }
    
    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator)
    {
        isFlicking = false
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
        
        let items = categoryProvider.getAll(but: .unknown, timeSlot.category)
        
        viewHandler?.cleanAll()
        viewHandler = ItemViewHandler<ViewType, Category>(items: items, attributeSelector: ({ ($0.icon.image, $0.color) }))
        
        currentCategoryBackgroundView?.removeFromSuperview()
        currentCategoryBackgroundView = UIView()
        currentCategoryBackgroundView?.backgroundColor = timeSlot.category.color
        currentCategoryBackgroundView?.layer.cornerRadius = 16
        addSubviewWithConstraints(currentCategoryBackgroundView!, basedOn: point)
        
        currentCategoryImageView?.removeFromSuperview()
        currentCategoryImageView = newImageView(with: UIImage(asset: timeSlot.category.icon), cornerRadius: 16, contentMode: .scaleAspectFit, basedOn: point)
        currentCategoryImageView?.isHidden = timeSlot.category == .unknown

        plusImageView?.removeFromSuperview()
        plusImageView = newImageView(with: UIImage(asset: Category.unknown.icon), cornerRadius: 16, contentMode: .scaleAspectFit, basedOn: point)
        plusImageView?.alpha = self.selectedItem != .unknown ? 0.0 : 1.0
        
        self.animate({ 
            self.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        }, duration: Constants.editAnimationDuration * 3)
        
        animate({ 
            self.plusImageView?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)
            self.plusImageView?.alpha = 1.0
        }, duration: 0.192, withControlPoints: 0.0, 0.0, 0.2, 1)
        
        animate({
            self.currentCategoryImageView?.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        }, duration: 0.102, withControlPoints: 0.4, 0.0, 1, 1)
        
        show(from: CGPoint(x: point.x - 16, y: point.y - 9))
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
        
        animate(firstSetpOfAnimation, duration: 0.192, withControlPoints: 0.0, 0.0, 0.2, 1) {
            self.animate(secondStepOfAnimation, duration: 0.09, withControlPoints: 0.0, 0.0, 0.2, 1, completion: cleanupAfterAnimation)
        }
        
        animate({ 
            self.backgroundColor = UIColor.white.withAlphaComponent(0)
        }, duration: animationDuration, options: [.curveLinear])
        
        var animationSequence = DelayedSequence.start()
        
        let delay = TimeInterval(0.02)
        let cellsToAnimate = viewHandler.visibleCells.filter({ $0.frame.intersects(bounds) }).reversed()
        
        for cell in cellsToAnimate
        {
            cell.layer.removeAllAnimations()
            animationSequence = animationSequence.after(delay, animate(cell, presenting: false))
        }
        
        animationSequence.after(animationDuration, cleanupAfterHide())
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
                
                let changesToAnimate = {
                    cell.layer.removeAllAnimations()
                    cell.transform = presenting ?
                        .identity :
                        scaleTransform
                }
                
                if presenting
                {
                    self.animate(changesToAnimate, duration: self.animationDuration, withControlPoints: 0.23, 1, 0.32, 1)
                }
                else
                {
                    self.animate(changesToAnimate, duration: self.animationDuration, withControlPoints: 0.175, 0.885, 0.32, 1)
                }
            }
        }
    }
    
    private func snapCellsToCorrrectPosition()
    {
        let cells = viewHandler.visibleCells
        
        let firstCell = cells.first!
        let tempTransform = firstCell.transform
        firstCell.transform = .identity
        
        let distanceBasedOnPageWidth = firstCell.center.x - leftBoundryX + pageWidth / 2
        let offset = abs(pageWidth - abs(distanceBasedOnPageWidth)) < pageWidth / 2 ?
            (distanceBasedOnPageWidth > 0 ? 1 : -1) * pageWidth - distanceBasedOnPageWidth :
            -distanceBasedOnPageWidth
        
        firstCell.transform = tempTransform
        
        let animationDuration = 0.334
        
        animate({
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
    private func animate(
        _ changes: @escaping ()->(),
        duration: Double,
        delay: Double = 0.0,
        options: [UIViewAnimationOptions] = [],
        withControlPoints c1x: Float = 0,
        _ c1y: Float = 0,
        _ c2x: Float = 0,
        _ c2y: Float = 0,
        completion: (()->())? = nil)
    {
        let timingFunction = CAMediaTimingFunction(controlPoints: c1x, c1y, c2x, c2y)
        
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(timingFunction)

        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: [],
            animations: changes) { (_) in
                completion?()
        }
        
        CATransaction.commit()
    }
    
    private func newImageView(with image: UIImage, cornerRadius: CGFloat, contentMode: UIViewContentMode, basedOn point: CGPoint) -> UIImageView
    {
        let imageView = UIImageView(image: image)
        imageView.layer.cornerRadius = cornerRadius
        imageView.contentMode = contentMode
        
        self.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(15)
            make.top.equalTo(point.y - 15.4)
            make.left.equalTo(point.x - 23.4)
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
    
    // MARK: - for hacky onboarding animations
    func getIcon(forCategory category: Category) -> UIImageView?
    {
        let color = category.color
        guard let cell = viewHandler.visibleCells.first(where: { (b) in b.backgroundColor == color }) else { return nil }
        return UIImageView(frame: cell.frame)
    }
    
    // MARK: - Math functions
    private func isInAllowedRange(_ cell: ViewType) -> Bool
    {
        return (cell.frame.minX > leftBoundryX && cell.frame.minX < rightBoundryX) || (cell.frame.maxX > leftBoundryX && cell.frame.maxX < rightBoundryX)
    }
    
    private func shouldFlick(for velocity: CGPoint) -> Bool
    {
        return abs( velocity.x ) > 200
    }
}
