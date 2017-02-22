import UIKit

class Wheel<ItemType> : UIControl, TrigonometryHelper, UIDynamicAnimatorDelegate
{
    typealias ViewType = UIButton
    typealias DismissType = ((Wheel<ItemType>) -> ())
    
    // MARK: - Flick components
    private var flickBehavior : UIDynamicItemBehavior!
    private var flickAnimator : UIDynamicAnimator!
    private var lastFlickPoint : CGPoint!
    private var flickView : UIView!
    private var flickViewAttachment : UIAttachmentBehavior!
    
    private var isSpinning : Bool = false
    {
        didSet
        {
            viewModel.visibleCells.forEach { (cell) in
                cell.isUserInteractionEnabled = !isSpinning
            }
        }
    }
    
    // MARK: - Pan gesture components
    private var panGesture : UIPanGestureRecognizer!
    private var lastPanPoint : CGPoint!
    
    // MARK: - Tap gesture components
    private var tapGesture : UITapGestureRecognizer!

    private let viewModel : WheelViewHandler<ViewType, ItemType>
    
    private(set) var selectedItem : ItemType?
    
    private let cellSize : CGSize
    private let radius : CGFloat
    private let startAngle : CGFloat
    private let endAngle : CGFloat
    private var centerPoint : CGPoint
    private let angleBetweenCells : CGFloat
    private let dismissAction : DismissType?
    
    private var measurementStartPoint : CGPoint
    {
        return CGPoint(x: centerPoint.x + radius, y: centerPoint.y)
    }
    
    private var cellDiagonalDistance: CGFloat
    {
        return sqrt(pow(cellSize.width, 2) + pow(cellSize.height, 2))
    }
    
    private let animationDuration = TimeInterval(0.225)
    
    private lazy var startAnglePoint : CGPoint = {
        return self.rotatePoint(target: self.measurementStartPoint, aroundOrigin: self.centerPoint, by: self.startAngle)
    }()
    
    private lazy var endAnglePoint : CGPoint = {
        return self.rotatePoint(target: self.measurementStartPoint, aroundOrigin: self.centerPoint, by: self.endAngle)
    }()
    
    private lazy var allowedPath : UIBezierPath = {
        let ovalRect = CGRect(origin: CGPoint(x: self.centerPoint.x - self.radius, y: self.centerPoint.y - self.radius), size: CGSize(width: self.radius * 2, height: self.radius * 2))
        let ovalPath = UIBezierPath()
        ovalPath.addArc(withCenter: CGPoint(x: ovalRect.midX, y: ovalRect.midY), radius: ovalRect.width / 2, startAngle: -self.endAngle, endAngle: -self.startAngle, clockwise: true)
        ovalPath.addLine(to: CGPoint(x: ovalRect.midX, y: ovalRect.midY))
        ovalPath.close()
        return ovalPath
    }()
    
    // MARK: - Init
    
    init(
        frame : CGRect,
        cellSize: CGSize,
        centerPoint: CGPoint,
        radius: CGFloat,
        startAngle: CGFloat,
        endAngle: CGFloat,
        angleBetweenCells: CGFloat,
        items: [ItemType],
        attributeSelector: @escaping ((ItemType) -> (UIImage, UIColor)),
        dismissAction: DismissType?)
    {
        if startAngle >= endAngle
        {
            fatalError("startAngle should be smaller than endAngle")
        }
        
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.angleBetweenCells = angleBetweenCells
        self.radius = radius
        self.centerPoint = centerPoint
        self.cellSize = cellSize
        self.dismissAction = dismissAction
        
        self.viewModel = WheelViewHandler<ViewType, ItemType>(items: items, attributeSelector: attributeSelector)
        
        super.init(frame: frame)
        
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
    
    // MARK: - Tap gesture logic
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer)
    {
        resetFlick()
        isSpinning = false
        
        let tapPoint: CGPoint = sender.location(in: self)
        if distance(a: tapPoint, b: centerPoint) > radius + cellSize.width
        {
            dismissAction?(self)
        }
    }
    
    // MARK: - Pan gesture logic
    
    @objc private func handlePan(_ sender: UIPanGestureRecognizer)
    {
        resetFlick()
        
        let panPoint: CGPoint = sender.location(in: self)
        
        switch sender.state {
        case .began:
            
            if distance(a: panPoint, b: centerPoint) > radius + cellDiagonalDistance * 1.5
            {
                dismissAction?(self)
                sender.isEnabled = false
                return
            }
            
            isSpinning = true
            lastPanPoint = panPoint
            
        case .changed:
            
            let angleToRotate = angle(startPoint: lastPanPoint, endPoint: panPoint, anchorPoint: centerPoint)
            
            handleMovement(angleToRotate: angleToRotate)
            
            lastPanPoint = panPoint
            
        case .ended:
            
            isSpinning = false
            
            let velocity = sender.velocity(in: self)
            
            if shouldFlick(for: velocity)
            {
                flick(with: velocity, from: lastPanPoint!)
            }
            
            lastPanPoint = nil
            
        default:
            isSpinning = false
        }
    }
    
    // MARK: - Flick logic
    
    private func flick(with velocity: CGPoint, from point: CGPoint)
    {
        resetFlick()
        
        flickAnimator = UIDynamicAnimator(referenceView: self)
        flickAnimator.delegate = self
        
        let flickViewStartingAngle = positiveAngle(startPoint: measurementStartPoint, endPoint: point, anchorPoint: centerPoint)
        let flickViewCenter = rotatePoint(target: measurementStartPoint, aroundOrigin: centerPoint, by: flickViewStartingAngle)
        flickView = UIView(frame: CGRect(origin: CGPoint(x: flickViewCenter.x - cellSize.width / 2, y: flickViewCenter.y - cellSize.height / 2), size: cellSize))
        flickView.isUserInteractionEnabled = false
        flickView.isHidden = true
        addSubview(flickView)
        
        flickViewAttachment = UIAttachmentBehavior(item: flickView, attachedToAnchor: centerPoint)
        flickAnimator.addBehavior(flickViewAttachment!)

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
        flickViewAttachment = nil
        lastFlickPoint = nil
    }
    
    func flickBehaviorAction()
    {
        guard let _ = self.lastFlickPoint
        else
        {
            self.lastFlickPoint = flickView.center
            return
        }
        
        let angleToRotate = angle(startPoint: self.lastFlickPoint, endPoint: flickView.center, anchorPoint: centerPoint)
        
        if distance(a: self.lastFlickPoint, b: flickView.center) == 0
        {
            isSpinning = false
        }
        
        handleMovement(angleToRotate: angleToRotate)
        
        self.lastFlickPoint = flickView.center
    }
    
    // MARK: - UIDynamicAnimatorDelegate
    
    func dynamicAnimatorWillResume(_ animator: UIDynamicAnimator)
    {
        isSpinning = true
    }
    
    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator)
    {
        isSpinning = false
    }
    
    // MARK: - Rotation logic
    
    private func handleMovement(angleToRotate: CGFloat)
    {
        let rotationDirection = angleToRotate < 0

        let cells = viewModel.visibleCells
        
        let pointToBaseMovement = rotatePoint(target: cells.first!.center, aroundOrigin: centerPoint, by: toPositive(angle: angleToRotate))
        
        for (index, cell) in cells.enumerated()
        {
            cell.center = rotatePoint(target: pointToBaseMovement, aroundOrigin: centerPoint, by: toPositive(angle: CGFloat(index) * angleBetweenCells))
            
            if !isInAllowedRange(point: cell.center)
            {
                viewModel.remove(cell: cell)
            }
        }
        
        guard var lastCellBasedOnRotationDirection = viewModel.lastVisibleCell(clockwise: rotationDirection) else { return }
        
        var angleOfLastPoint = positiveAngle(startPoint: measurementStartPoint, endPoint: lastCellBasedOnRotationDirection.center, anchorPoint: centerPoint)
        
        var edgeAngle = (rotationDirection ? endAngle : startAngle)
        edgeAngle = toPositive(angle: edgeAngle)
        
        while abs(abs(angleOfLastPoint) - edgeAngle) > angleBetweenCells
        {
            let newCell = viewModel.cell(before: lastCellBasedOnRotationDirection, clockwise: rotationDirection, cellSize: cellSize)
            newCell.addTarget(self, action: #selector(self.didSelectCell(_:)), for: .touchUpInside)
            newCell.center = rotatePoint(target: lastCellBasedOnRotationDirection.center, aroundOrigin: centerPoint, by: ( rotationDirection ? 1 : -1 ) * angleBetweenCells)
            newCell.isUserInteractionEnabled = !isSpinning
            
            addSubview(newCell)
            
            lastCellBasedOnRotationDirection = newCell
            angleOfLastPoint = positiveAngle(startPoint: measurementStartPoint, endPoint: lastCellBasedOnRotationDirection.center, anchorPoint: centerPoint)
        }
    }
    
    // MARK: - Presentation and dismissal logic
    
    func show(below view: UIView, showing numberToShow: Int = 5, startingAngle: CGFloat = CGFloat.pi / 2)
    {
        view.superview?.insertSubview(self, belowSubview: view)
        
        self.centerPoint = view.center
        
        self.panGesture.isEnabled = true
        
        var animationSequence = DelayedSequence.start()
        
        let delay = TimeInterval(0.04)
        var previousCell : ViewType?
        
        for index in 0..<numberToShow
        {
            let cell = viewModel.cell(before: previousCell, clockwise: true, cellSize: cellSize)
            cell.addTarget(self, action: #selector(self.didSelectCell(_:)), for: .touchUpInside)
            cell.center = rotatePoint(target: measurementStartPoint, aroundOrigin: centerPoint, by: toPositive(angle: startingAngle + CGFloat(index) * angleBetweenCells))
            cell.isHidden = true

            addSubview(cell)
            
            animationSequence = animationSequence.after(delay, animate(cell, presenting: true))
            
            previousCell = cell
        }
    }
    
    func hide()
    {
        var animationSequence = DelayedSequence.start()
        
        let delay = TimeInterval(0.02)
        
        for cell in viewModel.visibleCells.filter({ $0.frame.intersects(bounds) })
        {
            animationSequence = animationSequence.after(delay, animate(cell, presenting: false))
        }
        
        animationSequence.after(delay, cleanupAfterHide())
    }
    
    private func cleanupAfterHide() -> (TimeInterval) -> ()
    {
        return { delay in
            Timer.schedule(withDelay: delay)
            {
                self.resetFlick()
                self.viewModel.cleanAll()
                self.removeFromSuperview()
            }
        }
    }
    
    private func animate(_ cell: ViewType, presenting: Bool) -> (TimeInterval) -> ()
    {
        return { delay in
            Timer.schedule(withDelay: delay)
            {
                let translationTransform = CGAffineTransform(translationX: self.centerPoint.x - cell.center.x, y: self.centerPoint.y - cell.center.y)
                
                let scaleTransform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                
                cell.transform = presenting ?
                    translationTransform :
                    .identity
                
                cell.alpha = presenting ? 0.0 : 1.0
                
                cell.isHidden = false
                
                let timingFunction = CAMediaTimingFunction(controlPoints: 0.23, 1, 0.32, 1)
                
                CATransaction.begin()
                CATransaction.setAnimationTimingFunction(timingFunction)
                
                UIView.animate(withDuration: self.animationDuration, animations:
                {
                    cell.transform = presenting ?
                        .identity :
                        scaleTransform.concatenating(translationTransform)
                    
                    cell.alpha = presenting ? 1.0 : 0.0
                })
                
                CATransaction.commit()
            }
        }
    }
    
    // MARK: - SelectionHandling
    
    @objc private func didSelectCell(_ sender: ViewType)
    {
        selectedItem = viewModel.items[sender.tag]
        sendActions(for: .valueChanged)
    }
    
    // MARK: - Math functions
    
    private func isInAllowedRange(point: CGPoint) -> Bool
    {
        return allowedPath.contains(point)
    }
    
    private func shouldFlick(for velocity: CGPoint) -> Bool
    {
        return max( abs( velocity.x ) , abs( velocity.y ) ) > 200
    }
}
