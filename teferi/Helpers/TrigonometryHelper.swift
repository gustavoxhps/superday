//
//  CGTrigonometryHelper.swift
//  teferi
//
//  Created by Juxhin Bakalli on 15/02/2017.
//  Copyright © 2017 Toggl. All rights reserved.
//

import UIKit

protocol TrigonometryHelper
{
    func distance(a: CGPoint, b: CGPoint) -> CGFloat
    
    func squaredDistance(a: CGPoint, b: CGPoint) -> CGFloat
    
    func rotatePoint(target: CGPoint, aroundOrigin origin: CGPoint, by angle: CGFloat) -> CGPoint
    
    func positiveAngle(startPoint a: CGPoint, endPoint c: CGPoint, anchorPoint b: CGPoint) -> CGFloat
    
    func angle(startPoint a: CGPoint, endPoint c: CGPoint, anchorPoint b: CGPoint) -> CGFloat
    
    func toPositive(angle: CGFloat) -> CGFloat
}

extension TrigonometryHelper
{
    func distance(a: CGPoint, b: CGPoint) -> CGFloat
    {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
    }
    
    func squaredDistance(a: CGPoint, b: CGPoint) -> CGFloat
    {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat((xDist * xDist) + (yDist * yDist))
    }
    
    func rotatePoint(target: CGPoint, aroundOrigin origin: CGPoint, by angle: CGFloat) -> CGPoint
    {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        
        // TODO: create rotation matrix and rotate using multiplication instead
        
        let radius = sqrt(dx * dx + dy * dy)
        
        let currentAngle = atan2(dy, dx)
        
        let newAngle = currentAngle - angle
        
        let x = origin.x + radius * cos(newAngle)
        let y = origin.y + radius * sin(newAngle)
        
        return CGPoint(x: x, y: y)
    }
    
    func positiveAngle(startPoint a: CGPoint, endPoint c: CGPoint, anchorPoint b: CGPoint) -> CGFloat
    {
        let angleToReturn = angle(startPoint: a, endPoint: c, anchorPoint: b)
        
        return toPositive(angle: angleToReturn)
    }
    
    func angle(startPoint a: CGPoint, endPoint c: CGPoint, anchorPoint b: CGPoint) -> CGFloat
    {
        let baDx = a.x - b.x
        let baDy = a.y - b.y
        
        let bcDx = c.x - b.x
        let bcDy = c.y - b.y
        
        let dot = baDx * bcDx + baDy * bcDy
        let det = baDx * bcDy - baDy * bcDx
        
        let angleToReturn = -atan2(det, dot)
        
        return angleToReturn
    }
    
    func toPositive(angle: CGFloat) -> CGFloat
    {
        guard angle >= 0 else { return angle + 2 * CGFloat.pi }
        
        return angle
    }
}
