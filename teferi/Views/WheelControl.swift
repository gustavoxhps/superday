//
//  WheelControl.swift
//  teferi
//
//  Created by Juxhin Bakalli on 15/02/2017.
//  Copyright © 2017 Toggl. All rights reserved.
//

import UIKit

class WheelViewModel<V, T> where V: UIButton
{
    typealias attribute = (image: UIImage, color: UIColor)
    
    var visibleCells = [V]()
    private var reusableCells = Set<V>()
    
    private let items : [T]
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
    
    private func cellWithAttributes(cell: V, attributes: attribute) -> V
    {
        cell.backgroundColor = attributes.color
        cell.setImage(attributes.image, for: .normal)
        return cell
    }
    
    func remove(cell: V)
    {
        guard visibleCells.count > 2 else { return }
        
        let index = visibleCells.index(of: cell)
        visibleCells.remove(at: index!)
        cell.isHidden = true
        reusableCells.insert(cell)
    }
}

// TODO: split this class into a thing that spins, and a thing that manages the cells
class Wheel<T> : UIControl, TrigonometryHelper
{
    private var spinBehavior : UIDynamicItemBehavior?
    private var animator: UIDynamicAnimator!
    
    private var panGesture : UIPanGestureRecognizer!
    private var lastPanPoint : CGPoint!
    private var spinningView : UIView!
    private var spinningViewAttachment : UIAttachmentBehavior!
    private var lastSpinPoint : CGPoint?
    
    private let viewModel : WheelViewModel<UIButton, T>
    
    private let cellSize : CGSize
    private let radius : CGFloat
    private let startAngle : CGFloat
    private let endAngle : CGFloat
    var centerPoint : CGPoint
    
    private var startPoint : CGPoint {
        return CGPoint(x: centerPoint.x + radius, y: centerPoint.y)
    }
    
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
        attributeSelector: @escaping ((T) -> (UIImage, UIColor)))
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
        
        self.viewModel = WheelViewModel<UIButton, T>(items: items, attributeSelector: attributeSelector)
        
        super.init(frame: frame)
        
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
        
        var cell = viewModel.cell(before: nil, clockwise: true, cellSize: cellSize)
        cell.center = cellCenter
        
        addSubview(cell)
        
        var angleOfLastPoint = positiveAngle(startPoint: startPoint, endPoint: cell.center, anchorPoint: centerPoint)
        
        while abs(angleOfLastPoint - endAngle) > angleBetweenCells
        {
            let cellToAdd = viewModel.cell(before: cell, clockwise: true, cellSize: cellSize)
            cellToAdd.center = rotatePoint(target: cell.center, aroundOrigin: centerPoint, by: angleBetweenCells)
            self.addSubview(cellToAdd)
            
            cell = cellToAdd
            angleOfLastPoint = positiveAngle(startPoint: startPoint, endPoint: cell.center, anchorPoint: centerPoint)
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
        spinBehavior = nil
        
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
    
    func isInAllowedRange(point: CGPoint) -> Bool
    {
        // TODO: this should be doable with a simple dot product instead
        return allowedPath.contains(point)
    }
    
//    private lazy var spinningView : UIView = {
//        spinningView = UIView(frame: CGRect(origin: CGPoint(x: spinningViewCenter.x - cellSize.width / 2, y: spinningViewCenter.y - cellSize.height / 2), size: cellSize))
//        spinningView.isUserInteractionEnabled = false
//        spinningView.backgroundColor = .clear // TODO: hide instead
//        ret addSubview(spinningView)
//    }()
    
    func flick(with velocity: CGPoint)
    {
        let spinningViewStartingAngle = positiveAngle(startPoint: startPoint, endPoint: lastPanPoint!, anchorPoint: centerPoint)
        let spinningViewCenter = rotatePoint(target: startPoint, aroundOrigin: centerPoint, by: spinningViewStartingAngle)
        
        // TODO: consider putting the caching into a separete method
        if let _ = spinningView // TODO: compare against nil instead
        {
            animator.removeBehavior(spinningViewAttachment!)
            spinningView.center = spinningViewCenter
            animator.addBehavior(spinningViewAttachment!)
        }
        else
        {
            spinningView = UIView(frame: CGRect(origin: CGPoint(x: spinningViewCenter.x - cellSize.width / 2, y: spinningViewCenter.y - cellSize.height / 2), size: cellSize))
            spinningView.isUserInteractionEnabled = false
            spinningView.isHidden = true
            addSubview(spinningView)
            
            spinningViewAttachment = UIAttachmentBehavior(item: spinningView, attachedToAnchor: centerPoint)
            animator.addBehavior(spinningViewAttachment!)
        }
        
        safelyRemoveBehavior(behavior: spinBehavior)
        spinBehavior?.action = nil
        spinBehavior = nil
        
        spinBehavior = UIDynamicItemBehavior(items: [spinningView])
        spinBehavior!.addLinearVelocity(velocity, for: spinningView) // TODO: consider using tangental velocity directly (though this should not matter much)
        spinBehavior!.allowsRotation = false
        spinBehavior!.resistance = 4
        spinBehavior!.density = 1.5
//        spinBehavior!.action = spinBehaviorAction
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
    
//    func spinBehaviorAction()
//    {
//        guard let lastSpinPoint = lastSpinPoint else { return }
//        
//        let angleToRotate = angle(startPoint: lastSpinPoint, endPoint: spinningView.center, anchorPoint: centerPoint)
//        
//        handleMovement(angleToRotate: angleToRotate)
//        
//        self.lastSpinPoint = spinningView.center
//    }
    
    func handleMovement(angleToRotate: CGFloat)
    {
        let rotationDirection = angleToRotate < 0
        
        let cells = viewModel.visibleCells
        
        cells.forEach({ (cell) in
            // TODO: this is prone to drifting of cells (change in radius) due to rounding errors
            //       much better to work with angles directly, and simply calculate positions from those
            cell.center = rotatePoint(target: cell.center, aroundOrigin: centerPoint, by: toPositive(angle: angleToRotate))
            cell.isHidden = false
            if !isInAllowedRange(point: cell.center)
            {
                viewModel.remove(cell: cell)
            }
        })
        
        // TODO: the rotation direction should be determined inside this method, not outside
        guard var lastCellBasedOnRotationDirecation = viewModel.lastVisibleCell(clockwise: rotationDirection) else { return }
        
        var angleOfLastPoint = positiveAngle(startPoint: startPoint, endPoint: lastCellBasedOnRotationDirecation.center, anchorPoint: centerPoint)
        
        var edgeAngle = (rotationDirection ? endAngle : startAngle)
        edgeAngle = toPositive(angle: edgeAngle)
        
        while abs(abs(angleOfLastPoint) - edgeAngle) > angleBetweenCells
        {
            let newCell = viewModel.cell(before: lastCellBasedOnRotationDirecation, clockwise: rotationDirection, cellSize: cellSize)
            newCell.center = rotatePoint(target: lastCellBasedOnRotationDirecation.center, aroundOrigin: centerPoint, by: ( rotationDirection ? 1 : -1 ) * angleBetweenCells)
            newCell.isHidden = false
            
            if newCell.superview == nil
            {
                addSubview(newCell)
            }
            
            lastCellBasedOnRotationDirecation = newCell
            angleOfLastPoint = positiveAngle(startPoint: startPoint, endPoint: lastCellBasedOnRotationDirecation.center, anchorPoint: centerPoint)
        }
    }
    
    func safelyRemoveBehavior(behavior: UIDynamicBehavior?)
    {
        guard let behavior = behavior else { return }
        
        animator.removeBehavior(behavior)
    }
    
    //mark: - Math functions
    
    func shouldFlick(for velocity: CGPoint) -> Bool
    {
        // TODO: this check should probably check tangental velocity instead,
        //       or at least use euclidean distance to calculate the speed
        return max( abs( velocity.x ) , abs( velocity.y ) ) > 200
    }
}
