//
//  ChartCoordsSpaceLayer.swift
//  SwiftCharts
//
//  Created by ischuetz on 25/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

open class ChartCoordsSpaceLayer: ChartLayerBase {
    
    let xAxis: ChartAxis
    let yAxis: ChartAxis
    
    /// If layer is generating views as part of a transform (e.g. panning or zooming)
    var isTransform = false
    
    public init(xAxis: ChartAxis, yAxis: ChartAxis) {
        self.xAxis = xAxis
        self.yAxis = yAxis
    }
    
    open func modelLocToScreenLoc(x: Double, y: Double) -> CGPoint {
        return CGPoint(x: modelLocToScreenLoc(x: x), y: modelLocToScreenLoc(y: y))
    }
    
    open func modelLocToScreenLoc(x: Double) -> CGFloat {
        return xAxis.innerScreenLocForScalar(x) / (chart?.contentView.transform.a ?? 1)
    }
    
    open func modelLocToScreenLoc(y: Double) -> CGFloat {
        return yAxis.innerScreenLocForScalar(y) / (chart?.contentView.transform.d ?? 1)
    }
    
    open func scalarForScreenLoc(x: CGFloat) -> Double {
        return xAxis.innerScalarForScreenLoc(x * (chart?.contentView.transform.a ?? 1))
    }
    
    open func scalarForScreenLoc(y: CGFloat) -> Double {
        return yAxis.innerScalarForScreenLoc(y * (chart?.contentView.transform.d ?? 1))
    }
    
    open func globalToDrawersContainerCoordinates(_ point: CGPoint) -> CGPoint? {
        guard let chart = chart else {return nil}
        return point.substract(chart.containerView.frame.origin)
    }
    
    open func containerToGlobalCoordinates(_ point: CGPoint) -> CGPoint? {
        guard let chart = chart else {return nil}
        return point.add(chart.containerView.frame.origin)
    }

    open func contentToContainerCoordinates(_ point: CGPoint) -> CGPoint? {
        guard let chart = chart else {return nil}
        let containerX = (point.x * chart.contentView.transform.a) + chart.contentView.frame.minX
        let containerY = (point.y * chart.contentView.transform.d) + chart.contentView.frame.minY
        return CGPoint(x: containerX, y: containerY)
    }
    
    open func contentToGlobalCoordinates(_ point: CGPoint) -> CGPoint? {
        return contentToContainerCoordinates(point).flatMap{containerToGlobalCoordinates($0)}
    }
    
    open func containerToGlobalScreenLoc(_ chartPoint: ChartPoint) -> CGPoint? {
        let containerScreenLoc = CGPoint(x: modelLocToScreenLoc(x: chartPoint.x.scalar), y: modelLocToScreenLoc(y: chartPoint.y.scalar))
        return containerToGlobalCoordinates(containerScreenLoc)
    }
}
