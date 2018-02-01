//
//  ChartPointsLineLayer.swift
//  SwiftCharts
//
//  Created by ischuetz on 25/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

public enum LineJoin {
    case miter
    case round
    case bevel
    
    var CALayerString: String {
        switch self {
        case .miter: return kCALineJoinMiter
        case .round: return kCALineCapRound
        case .bevel: return kCALineJoinBevel
        }
    }
    
    var CGValue: CGLineJoin {
        switch self {
        case .miter: return .miter
        case .round: return .round
        case .bevel: return .bevel
        }
    }
}

public enum LineCap {
    case butt
    case round
    case square
    
    var CALayerString: String {
        switch self {
        case .butt: return kCALineCapButt
        case .round: return kCALineCapRound
        case .square: return kCALineCapSquare
        }
    }
    
    var CGValue: CGLineCap {
        switch self {
        case .butt: return .butt
        case .round: return .round
        case .square: return .square
        }
    }
}

private struct ScreenLine {
    let points: [CGPoint]
    let color: UIColor
    let lineWidth: CGFloat
    let lineJoin: LineJoin
    let lineCap: LineCap
    let animDuration: Float
    let animDelay: Float
    
    init(points: [CGPoint], color: UIColor, lineWidth: CGFloat, lineJoin: LineJoin, lineCap: LineCap, animDuration: Float, animDelay: Float) {
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.lineJoin = lineJoin
        self.lineCap = lineCap
        self.animDuration = animDuration
        self.animDelay = animDelay
    }
}

open class ChartPointsLineLayer<T: ChartPoint>: ChartPointsLayer<T> {
    fileprivate var lineModels: [ChartLineModel<T>]
    fileprivate var lineViews: [ChartLinesView] = []
    fileprivate let pathGenerator: ChartLinesViewPathGenerator

    fileprivate let useView: Bool
    
    public init(xAxis: ChartAxis, yAxis: ChartAxis, lineModels: [ChartLineModel<T>], pathGenerator: ChartLinesViewPathGenerator = StraightLinePathGenerator(), displayDelay: Float = 0, useView: Bool = true) {
        
        self.lineModels = lineModels
        self.pathGenerator = pathGenerator
        self.useView = useView
        
        let chartPoints: [T] = lineModels.flatMap{$0.chartPoints}
        
        super.init(xAxis: xAxis, yAxis: yAxis, chartPoints: chartPoints, displayDelay: displayDelay)
    }
    
    fileprivate func toScreenLine(lineModel: ChartLineModel<T>, chart: Chart) -> ScreenLine {
        return ScreenLine(
            points: lineModel.chartPoints.map{self.chartPointScreenLoc($0)},
            color: lineModel.lineColor,
            lineWidth: lineModel.lineWidth,
            lineJoin: lineModel.lineJoin,
            lineCap: lineModel.lineCap,
            animDuration: lineModel.animDuration,
            animDelay: lineModel.animDelay
        )
    }
    
    override func display(chart: Chart) {
        if useView {
            let screenLines = self.lineModels.map{self.toScreenLine(lineModel: $0, chart: chart)}
            
            for screenLine in screenLines {
                let lineView = ChartLinesView(
                    path: self.pathGenerator.generatePath(points: screenLine.points, lineWidth: screenLine.lineWidth),
                    frame: chart.contentView.bounds,
                    lineColor: screenLine.color,
                    lineWidth: screenLine.lineWidth,
                    lineJoin: screenLine.lineJoin,
                    lineCap: screenLine.lineCap,
                    animDuration: self.isTransform ? 0 : screenLine.animDuration,
                    animDelay: self.isTransform ? 0 : screenLine.animDelay)
                
                self.lineViews.append(lineView)
                lineView.isUserInteractionEnabled = false
                chart.addSubview(lineView)
            }
        }
    }
    
    
    override open func chartDrawersContentViewDrawing(context: CGContext, chart: Chart, view: UIView) {
        if !useView {
            for lineModel in lineModels {
                context.setStrokeColor(lineModel.lineColor.cgColor)
                context.setLineWidth(lineModel.lineWidth)
                context.setLineJoin(lineModel.lineJoin.CGValue)
                context.setLineCap(lineModel.lineCap.CGValue)
                for i in 0..<lineModel.chartPoints.count {
                    let chartPoint = lineModel.chartPoints[i]
                    let p1 = modelLocToScreenLoc(x: chartPoint.x.scalar, y: chartPoint.y.scalar)
                    context.move(to: CGPoint(x: p1.x, y: p1.y))
                    if i < lineModel.chartPoints.count - 1 {
                        let nextChartPoint = lineModel.chartPoints[i + 1]
                        let p2 = modelLocToScreenLoc(x: nextChartPoint.x.scalar, y: nextChartPoint.y.scalar)
                        context.addLine(to: CGPoint(x: p2.x, y: p2.y))
                    }
                }
                context.strokePath()
            }
        }
    }
    
    open override func modelLocToScreenLoc(x: Double) -> CGFloat {
        return useView ? super.modelLocToScreenLoc(x: x) : xAxis.screenLocForScalar(x) - (chart?.containerFrame.origin.x ?? 0)
    }
    
    open override func modelLocToScreenLoc(y: Double) -> CGFloat {
        return useView ? super.modelLocToScreenLoc(y: y) : yAxis.screenLocForScalar(y) - (chart?.containerFrame.origin.y ?? 0)
    }
    
    open override func zoom(_ scaleX: CGFloat, scaleY: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        if !useView {
            chart?.drawersContentView.setNeedsDisplay()
        }
    }
    
    open override func zoom(_ x: CGFloat, y: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        if !useView {
            chart?.drawersContentView.setNeedsDisplay()
        }
    }
    
    open override func pan(_ deltaX: CGFloat, deltaY: CGFloat) {
        if !useView {
            chart?.drawersContentView.setNeedsDisplay()
        }
    }
}
