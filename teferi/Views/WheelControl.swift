//
//  WheelControl.swift
//  teferi
//
//  Created by Juxhin Bakalli on 15/02/2017.
//  Copyright © 2017 Toggl. All rights reserved.
//

import UIKit

// TODO: split this class into a thing that spins, and a thing that manages the cells
class WheelControl<T> : UIControl, TrigonometryHelper
{
    private var spinBehavior : UIDynamicItemBehavior?
    private var animator: UIDynamicAnimator!
    
    private var panGesture : UIPanGestureRecognizer!
    private var lastPanPoint : CGPoint!
    private var spinningView : UIView!
    private var spinningViewAttachment : UIAttachmentBehavior!
    private var lastSpinPoint : CGPoint!
    
    private var cells = [UIView]()
    private var reusableCells = Set<UIView>() //swift has no queue or stack that can be try-popped?
    
    private var newCell : UIView {
        guard !reusableCells.isEmpty else {
            let cell = UIView(frame: CGRect(origin: .zero, size: cellSize))
            cell.backgroundColor = UIColor.gray
            //cell.alpha = 0.1
            cell.layer.cornerRadius = min(cellSize.width, cellSize.height) / 2
            addSubview(cell)
            return cell
        }
        return reusableCells.removeFirst()
    }
    
    private var items : [T]
    
    private let cellSize : CGSize
    private let radius : CGFloat
    private let startAngle : CGFloat
    private let endAngle : CGFloat
    private let centerPoint : CGPoint
    
    private var startPoint : CGPoint!
    
    private let angleBetweenCells : CGFloat
    
    private lazy var startAnglePoint : CGPoint = {
        return self.rotatePoint(target: self.startPoint, aroundOrigin: self.centerPoint, by: self.startAngle)
    }()
    
    private lazy var endAnglePoint : CGPoint = {
        return self.rotatePoint(target: self.startPoint, aroundOrigin: self.centerPoint, by: self.endAngle)
    }()
    
    private lazy var allowedPath : UIBezierPath = {
        let ovalRect = CGRect(origin: CGPoint(x: self.centerPoint.x - self.radius, y: self.centerPoint.y - self.radius), size: CGSize(width: self.radius * 2, height: self.radius * 2))
        let ovalPath = UIBezierPath()
        ovalPath.addArc(withCenter: CGPoint(x: ovalRect.midX, y: ovalRect.midY), radius: ovalRect.width / 2, startAngle: -self.endAngle, endAngle: -self.startAngle, clockwise: true)
        ovalPath.addLine(to: CGPoint(x: ovalRect.midX, y: ovalRect.midY))
        ovalPath.close()
        return ovalPath
    }()
    
    init(
        frame : CGRect,
        cellSize: CGSize,
        centerPoint: CGPoint,
        radius: CGFloat,
        startAngle: CGFloat,
        endAngle: CGFloat,
        angleBetweenCells: CGFloat,
        items: [T],
        attributeSelector: ((T) -> (UIImage, UIColor)))
    {
        // TODO: consider fatalError or otherwise ensuring the parameters cannot be messed up with
        // for example by switching them if they are inverted.
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
        
        self.items = items
        
        super.init(frame: frame)
        
        startPoint = CGPoint(x: centerPoint.x + radius, y: centerPoint.y)
        
        animator = UIDynamicAnimator(referenceView: self)
        animator.setValue(true, forKey: "debugEnabled")
        
        setupCells()
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        panGesture.delaysTouchesBegan = false
        addGestureRecognizer(panGesture)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCells()
    {
        // TODO: this method looks like it can probably be more concise
        let firstAngle = CGFloat.pi / 2
        
        let cellCenter = rotatePoint(target: startPoint, aroundOrigin: centerPoint, by: firstAngle)
        
        let cell = newCell
        cell.center = cellCenter
        
        self.cells.append(cell)
        self.addSubview(cell)
        
        var angleOfLastPoint = positiveAngle(startPoint: startPoint, endPoint: cell.center, anchorPoint: centerPoint)
        
        while abs(angleOfLastPoint - endAngle) > angleBetweenCells
        {
            let cellToAdd = newCell
            cellToAdd.center = rotatePoint(target: cells.last!.center, aroundOrigin: centerPoint, by: angleBetweenCells)
            self.cells.append(cellToAdd)
            self.addSubview(cellToAdd)
            
            angleOfLastPoint = positiveAngle(startPoint: startPoint, endPoint: cells.last!.center, anchorPoint: centerPoint)
        }
    }
    
    func handlePan(_ sender: UIPanGestureRecognizer)
    {
        let panPoint: CGPoint = sender.location(in: self)
        
        if let _ = spinningView
        {
            safelyRemoveBehavior(behavior: self.spinningViewAttachment)
        }
        
        safelyRemoveBehavior(behavior: spinBehavior)
        
        switch sender.state {
        case .began:
            
            lastPanPoint = panPoint
            
        case .changed:
            
            let angleToRotate = angle(startPoint: lastPanPoint, endPoint: panPoint, anchorPoint: centerPoint)
            
            handleMovement(angleToRotate: angleToRotate)
            
            lastPanPoint = panPoint
            
        case .ended:
            
            let velocity = sender.velocity(in: self)
            
            flick(with: velocity)
            
            lastPanPoint = nil
            
        default:
            break
        }
    }
    
    func isInAllowedRange(point: CGPoint) -> Bool
    {
        // TODO: this should be doable with a simple dot product instead
        return allowedPath.contains(point)
    }
    
    func flick(with velocity: CGPoint, force: Bool = false)
    {
        if needsMomentum(for: velocity) || force
        {
            let spinningViewStartingAngle = positiveAngle(startPoint: startPoint, endPoint: lastPanPoint!, anchorPoint: centerPoint)
            let spinningViewCenter = rotatePoint(target: startPoint, aroundOrigin: centerPoint, by: spinningViewStartingAngle)
            
            // TODO: consider putting the caching into a separete method
            if let _ = spinningView // TODO: compare against nil instead
            {
                spinningView.center = spinningViewCenter
                animator.addBehavior(spinningViewAttachment!)
            }
            else
            {
                spinningView = UIView(frame: CGRect(origin: CGPoint(x: spinningViewCenter.x - cellSize.width / 2, y: spinningViewCenter.y - cellSize.height / 2), size: cellSize))
                spinningView.isUserInteractionEnabled = false
                spinningView.backgroundColor = .clear // TODO: hide instead
                addSubview(spinningView)
                
                spinningViewAttachment = UIAttachmentBehavior(item: spinningView, attachedToAnchor: centerPoint)
                animator.addBehavior(spinningViewAttachment!)
            }
            
            spinBehavior = UIDynamicItemBehavior(items: [spinningView])
            spinBehavior!.addLinearVelocity(velocity, for: spinningView) // TODO: consider using tangental velocity directly (though this should not matter much)
            spinBehavior!.allowsRotation = false
            spinBehavior!.resistance = 4
            spinBehavior!.density = 1.5
            spinBehavior?.action = { [weak self] in
                
                guard
                    let lastSpinPoint = self?.lastSpinPoint,
                    let spinningView = self?.spinningView,
                    let centerPoint = self?.centerPoint,
                    let angle = self?.angle(startPoint: lastSpinPoint, endPoint: spinningView.center, anchorPoint: centerPoint)
                    
                    else {
                        self?.lastSpinPoint = self?.spinningView.center
                        return
                }
                
                self?.handleMovement(angleToRotate: angle)
                
                self?.lastSpinPoint = self?.spinningView.center
                
            }
            animator.addBehavior(spinBehavior!)
        }
    }
    
    func handleMovement(angleToRotate: CGFloat)
    {
        let clockwiseDirection = angleToRotate < 0
        
        cells.forEach({ (cell) in
            // TODO: this is prone to drifting of cells (change in radius) due to rounding errors
            //       much better to work with angles directly, and simply calculate positions from those
            cell.center = rotatePoint(target: cell.center, aroundOrigin: centerPoint, by: toPozitive(angle: angleToRotate))
            cell.isHidden = false
            if !isInAllowedRange(point: cell.center)
            {
                remove(cell: cell)
            }
        })
        
        // TODO: the rotation direction should be determined inside this method, not outside
        guard var lastCellBasedOnRotationDirecation = clockwiseDirection ? cells.last : cells.first
            else { return }
        
        var angleOfLastPoint = positiveAngle(startPoint: startPoint, endPoint: lastCellBasedOnRotationDirecation.center, anchorPoint: centerPoint)
        
        var edgeAngle = (clockwiseDirection ? endAngle : startAngle)
        if edgeAngle < 0
        {
            edgeAngle += 2 * CGFloat.pi
        }
        
        while abs(abs(angleOfLastPoint) - edgeAngle) > angleBetweenCells
        {
            let cellToAdd = newCell
            cellToAdd.center = rotatePoint(target: lastCellBasedOnRotationDirecation.center, aroundOrigin: centerPoint, by: ( clockwiseDirection ? 1 : -1 ) * angleBetweenCells)
            cellToAdd.isHidden = false
            cellToAdd.backgroundColor = .red
            cells.insert(cellToAdd, at: ( clockwiseDirection ? cells.endIndex : cells.startIndex ))
            
            lastCellBasedOnRotationDirecation = clockwiseDirection ? cells.last! : cells.first!
            angleOfLastPoint = positiveAngle(startPoint: startPoint, endPoint: lastCellBasedOnRotationDirecation.center, anchorPoint: centerPoint)
        }
    }
    
    func remove(cell: UIView)
    {
        guard cells.count > 1 else { return }
        
        cell.isHidden = true
        let index = cells.index(of: cell)
        cells.remove(at: index!)
        reusableCells.insert(cell)
    }
    
    func safelyRemoveBehavior(behavior: UIDynamicBehavior?)
    {
        guard let behavior = behavior else { return }
        
        animator.removeBehavior(behavior)
    }
    
    //mark: - Math functions
    
    func needsMomentum(for velocity: CGPoint) -> Bool
    {
        // TODO: this check should probably check tangental velocity instead,
        //       or at least use euclidean distance to calculate the speed
        return max( abs( velocity.x ) , abs( velocity.y ) ) > 500
    }
}
