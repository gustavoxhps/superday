import UIKit

class Wheel<ItemType> : UIControl, TrigonometryHelper
{
    typealias ViewType = UIButton
    
    // MARK: - Flick components
    private var flickBehavior : UIDynamicItemBehavior!
    private var flickAnimator : UIDynamicAnimator!
    private var lastFlickPoint : CGPoint!
    private var flickView : UIView!
    private var flickViewAttachment : UIAttachmentBehavior!
    
    // MARK: - Pan gesture components
    private var panGesture : UIPanGestureRecognizer!
    private var lastPanPoint : CGPoint!
    
    // MARK: - Tap gesture components
    private var tapGesture : UITapGestureRecognizer!

    private let viewModel : WheelViewModel<ViewType, ItemType>
    
    private(set) var selectedItem : ItemType?
    
    private let cellSize : CGSize
    private let radius : CGFloat
    private let startAngle : CGFloat
    private let endAngle : CGFloat
    private var centerPoint : CGPoint
    private let angleBetweenCells : CGFloat
    
    private var measurementStartPoint : CGPoint
    {
        return CGPoint(x: centerPoint.x + radius, y: centerPoint.y)
    }
    
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
        attributeSelector: @escaping ((ItemType) -> (UIImage, UIColor)))
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
        
        self.viewModel = WheelViewModel<ViewType, ItemType>(items: items, attributeSelector: attributeSelector)
        
        super.init(frame: frame)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        panGesture.delaysTouchesBegan = false
        addGestureRecognizer(panGesture)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        tapGesture.delaysTouchesBegan = false
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
    }
    
    // MARK: - Pan gesture logic
    @objc private func handlePan(_ sender: UIPanGestureRecognizer)
    {
        resetFlick()
        
        let panPoint: CGPoint = sender.location(in: self)
        
        switch sender.state {
        case .began:
            
            lastPanPoint = panPoint
            
        case .changed:
            
            let angleToRotate = angle(startPoint: lastPanPoint, endPoint: panPoint, anchorPoint: centerPoint)
            
            handleMovement(angleToRotate: angleToRotate)
            
            lastPanPoint = panPoint
            
        case .ended:
            
            let velocity = sender.velocity(in: self)
            
            if shouldFlick(for: velocity)
            {
                flick(with: velocity)
            }
            
            lastPanPoint = nil
            
        default:
            break
        }
    }
    
    // MARK: - Flick logic
    private func flick(with velocity: CGPoint)
    {
        resetFlick()
        
        flickAnimator = UIDynamicAnimator(referenceView: self)
//        flickAnimator.setValue(true, forKey: "debugEnabled")
        
        let flickViewStartingAngle = positiveAngle(startPoint: measurementStartPoint, endPoint: lastPanPoint!, anchorPoint: centerPoint)
        let flickViewCenter = rotatePoint(target: measurementStartPoint, aroundOrigin: centerPoint, by: flickViewStartingAngle)
        flickView = UIView(frame: CGRect(origin: CGPoint(x: flickViewCenter.x - cellSize.width / 2, y: flickViewCenter.y - cellSize.height / 2), size: cellSize))
        flickView.isUserInteractionEnabled = false
        flickView.isHidden = true
        addSubview(flickView)
        
        flickViewAttachment = UIAttachmentBehavior(item: flickView, attachedToAnchor: centerPoint)
        flickAnimator.addBehavior(flickViewAttachment!)

        flickBehavior = UIDynamicItemBehavior(items: [flickView])
        flickBehavior.addLinearVelocity(velocity, for: flickView) // TODO: consider using tangental velocity directly (though this should not matter much)
        flickBehavior.allowsRotation = false
        flickBehavior.resistance = 4
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
        guard let lastFlickPoint = lastFlickPoint
        else
        {
            self.lastFlickPoint = flickView.center
            return
        }
        
        let angleToRotate = angle(startPoint: lastFlickPoint, endPoint: flickView.center, anchorPoint: centerPoint)
        
        handleMovement(angleToRotate: angleToRotate)
        
        self.lastFlickPoint = flickView.center
    }
    
    // MARK: - Rotation logic
    private func handleMovement(angleToRotate: CGFloat)
    {
        let rotationDirection = angleToRotate < 0

        let cells = viewModel.visibleCells
        
        cells.forEach({ (cell) in
            // TODO: this is prone to drifting of cells (change in radius) due to rounding errors
            //       much better to work with angles directly, and simply calculate positions from those
            cell.center = rotatePoint(target: cell.center, aroundOrigin: centerPoint, by: toPositive(angle: angleToRotate))

            if !isInAllowedRange(point: cell.center)
            {
                viewModel.remove(cell: cell)
            }
        })
        
        guard var lastCellBasedOnRotationDirecation = viewModel.lastVisibleCell(clockwise: rotationDirection) else { return }
        
        var angleOfLastPoint = positiveAngle(startPoint: measurementStartPoint, endPoint: lastCellBasedOnRotationDirecation.center, anchorPoint: centerPoint)
        
        var edgeAngle = (rotationDirection ? endAngle : startAngle)
        edgeAngle = toPositive(angle: edgeAngle)
        
        while abs(abs(angleOfLastPoint) - edgeAngle) > angleBetweenCells
        {
            let newCell = viewModel.cell(before: lastCellBasedOnRotationDirecation, clockwise: rotationDirection, cellSize: cellSize)
            newCell.addTarget(self, action: #selector(self.didSelectCell(_:)), for: .touchUpInside)
            newCell.center = rotatePoint(target: lastCellBasedOnRotationDirecation.center, aroundOrigin: centerPoint, by: ( rotationDirection ? 1 : -1 ) * angleBetweenCells)
            
            addSubview(newCell)
            
            lastCellBasedOnRotationDirecation = newCell
            angleOfLastPoint = positiveAngle(startPoint: measurementStartPoint, endPoint: lastCellBasedOnRotationDirecation.center, anchorPoint: centerPoint)
        }
    }
    
    // MARK: - Presentation and dismissal logic
    func show(below view: UIView, showing nuberToShow: Int = 5, startingAngle: CGFloat = CGFloat.pi / 2)
    {
        view.superview?.insertSubview(self, belowSubview: view)
        
        self.centerPoint = view.center
        
        var animationSequence = DelayedSequence.start()
        
        let delay = 0.04
        var previewsCell : ViewType?
        
        for index in 0..<nuberToShow
        {
            let cell = viewModel.cell(before: previewsCell, clockwise: true, cellSize: cellSize)
            cell.addTarget(self, action: #selector(self.didSelectCell(_:)), for: .touchUpInside)
            cell.center = rotatePoint(target: measurementStartPoint, aroundOrigin: centerPoint, by: toPositive(angle: startingAngle + CGFloat(index) * angleBetweenCells))
            cell.isHidden = true

            addSubview(cell)
            
            animationSequence = animationSequence.after(TimeInterval(delay), animate(cell, presenting: true))
            
            previewsCell = cell
        }
    }
    
    func hide()
    {
        var animationSequence = DelayedSequence.start()
        
        let delay = 0.02
        
        for cell in viewModel.visibleCells.filter({ $0.frame.intersects(bounds) })
        {
            animationSequence = animationSequence.after(TimeInterval(delay), animate(cell, presenting: false))
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
                cell.transform = presenting ?
                    CGAffineTransform(translationX: self.centerPoint.x - cell.center.x, y: self.centerPoint.y - cell.center.y) :
                    CGAffineTransform.identity
                
                cell.isHidden = false
                
                let timingFunction = CAMediaTimingFunction(controlPoints: 0.23, 1, 0.32, 1)
                
                CATransaction.begin()
                CATransaction.setAnimationTimingFunction(timingFunction)
                
                UIView.animate(withDuration: 0.225, animations: {
                    cell.transform = presenting ?
                        CGAffineTransform.identity :
                        CGAffineTransform(translationX: self.centerPoint.x - cell.center.x, y: self.centerPoint.y - cell.center.y)
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
        // TODO: this should be doable with a simple dot product instead
        return allowedPath.contains(point)
    }
    
    private func shouldFlick(for velocity: CGPoint) -> Bool
    {
        // TODO: this check should probably check tangental velocity instead,
        //       or at least use euclidean distance to calculate the speed
        return max( abs( velocity.x ) , abs( velocity.y ) ) > 200
    }
}
