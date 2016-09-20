//
//  CGPoint.swift
//  SwiftCharts
//
//  Created by ischuetz on 30/07/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

extension CGPoint {

    func distance(_ point: CGPoint) -> CGFloat {
        return CGFloat(hypotf(Float(x) - Float(point.x), Float(y) - Float(point.y)))
    }
    
    func add(_ point: CGPoint) -> CGPoint {
        return offset(x: point.x, y: point.y)
    }
    
    func substract(_ point: CGPoint) -> CGPoint {
        return offset(x: -point.x, y: -point.y)
    }
    
    func offset(x: CGFloat = 0, y: CGFloat = 0) -> CGPoint {
        return CGPoint(x: self.x + x, y: self.y + y)
    }
    
    func surroundingRect(_ size: CGFloat) -> CGRect {
        return CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)
    }
    
    func nearest(_ intersections: [CGPoint]) -> (distance: CGFloat, point: CGPoint)? {
        var minDistancePoint: (distance: CGFloat, point: CGPoint)? = nil
        for intersection in intersections {
            let dist = distance(intersection)
            if (minDistancePoint.map{dist < $0.0}) ?? true {
                minDistancePoint = (dist, intersection)
            }
        }
        return minDistancePoint
    }
}
