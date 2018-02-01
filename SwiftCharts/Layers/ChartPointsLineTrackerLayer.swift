//
//  ChartPointsTrackerLayer.swift
//  swift_charts
//
//  Created by ischuetz on 16/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

public struct ChartPointsLineTrackerLayerThumbSettings {
    let thumbSize: CGFloat
    let thumbBorderWidth: CGFloat
    let thumbBorderColor: UIColor
    
    public init(thumbSize: CGFloat, thumbBorderWidth: CGFloat = 4, thumbBorderColor: UIColor = UIColor.black) {
        self.thumbSize = thumbSize
        self.thumbBorderWidth = thumbBorderWidth
        self.thumbBorderColor = thumbBorderColor
    }
}

public struct ChartPointsLineTrackerLayerSettings {
    let thumbSettings: ChartPointsLineTrackerLayerThumbSettings? // nil -> no thumb
    let selectNearest: Bool
    
    public init(thumbSettings: ChartPointsLineTrackerLayerThumbSettings? = nil, selectNearest: Bool = false) {
        self.thumbSettings = thumbSettings
        self.selectNearest = selectNearest
    }
}

public struct ChartPointWithScreenLoc<T: ChartPoint>: CustomDebugStringConvertible {
    public let chartPoint: T
    public var screenLoc: CGPoint
    
    init(chartPoint: T, screenLoc: CGPoint) {
        self.chartPoint = chartPoint
        self.screenLoc = screenLoc
    }
    
    func copy(_ chartPoint: T? = nil, screenLoc: CGPoint? = nil) -> ChartPointWithScreenLoc<T> {
        return ChartPointWithScreenLoc(
            chartPoint: chartPoint ?? self.chartPoint,
            screenLoc: screenLoc ?? self.screenLoc
        )
    }
    
    public var debugDescription: String {
        return "chartPoint: \(chartPoint), screenLoc: \(screenLoc)"
    }
}

open class ChartPointsLineTrackerLayer<T: ChartPoint>: ChartPointsLayer<T> {
    
    fileprivate let lineColor: UIColor
    fileprivate let animDuration: Float
    fileprivate let animDelay: Float
    
    fileprivate let settings: ChartPointsLineTrackerLayerSettings

    fileprivate var isTracking: Bool = false

    open var positionUpdateHandler: (([ChartPointWithScreenLoc<T>]) -> Void)?
    
    open let lines: [[T]]
    open var lineModels: [[ChartPointLayerModel<T>]] = []
    
    fileprivate var currentIntersections: [CGPoint] = []
    
    public init(xAxis: ChartAxis, yAxis: ChartAxis, lines: [[T]], lineColor: UIColor, animDuration: Float, animDelay: Float, settings: ChartPointsLineTrackerLayerSettings, positionUpdateHandler: (([ChartPointWithScreenLoc<T>]) -> Void)? = nil) {
        self.lineColor = lineColor
        self.animDuration = animDuration
        self.animDelay = animDelay
        self.settings = settings
        self.positionUpdateHandler = positionUpdateHandler
        self.lines = lines
        super.init(xAxis: xAxis, yAxis: yAxis, chartPoints: Array(lines.joined()))
    }

    fileprivate func linesIntersection(line1P1: CGPoint, line1P2: CGPoint, line2P1: CGPoint, line2P2: CGPoint) -> CGPoint? {
        return self.findLineIntersection(p0X: line1P1.x, p0y: line1P1.y, p1x: line1P2.x, p1y: line1P2.y, p2x: line2P1.x, p2y: line2P1.y, p3x: line2P2.x, p3y: line2P2.y)
    }
    
    override func initChartPointModels() {
        lineModels = lines.map{generateChartPointModels($0)}
        chartPointsModels = Array(lineModels.joined()) // consistency
    }
    
    override func updateChartPointsScreenLocations() {
        super.updateChartPointsScreenLocations()
        for i in 0..<lineModels.count {
            let updatedLineModel = updateChartPointsScreenLocations(lineModels[i])
            lineModels[i] = updatedLineModel
        }
    }
    
    // src: http://stackoverflow.com/a/14795484/930450 (modified)
    fileprivate func findLineIntersection(p0X: CGFloat , p0y: CGFloat, p1x: CGFloat, p1y: CGFloat, p2x: CGFloat, p2y: CGFloat, p3x: CGFloat, p3y: CGFloat) -> CGPoint? {
        
        var s02x: CGFloat, s02y: CGFloat, s10x: CGFloat, s10y: CGFloat, s32x: CGFloat, s32y: CGFloat, sNumer: CGFloat, tNumer: CGFloat, denom: CGFloat, t: CGFloat;
        
        s10x = p1x - p0X
        s10y = p1y - p0y
        s32x = p3x - p2x
        s32y = p3y - p2y
        
        denom = s10x * s32y - s32x * s10y
        if denom =~ 0 {
            return nil // Collinear
        }
        let denomPositive: Bool = denom > 0
        
        s02x = p0X - p2x
        s02y = p0y - p2y
        sNumer = s10x * s02y - s10y * s02x
        if (sNumer < 0) == denomPositive {
            return nil // No collision
        }
        
        tNumer = s32x * s02y - s32y * s02x
        if (tNumer < 0) == denomPositive {
            return nil // No collision
        }
        if ((sNumer > denom) == denomPositive) || ((tNumer > denom) == denomPositive) {
            return nil // No collision
        }
        
        // Collision detected
        t = tNumer / denom
        let i_x = p0X + (t * s10x)
        let i_y = p0y + (t * s10y)
        return CGPoint(x: i_x, y: i_y)
    }
    
    fileprivate func intersectsWithChartPointLines(_ rect: CGRect) -> Bool {
        let rectLines = rect.asLinesArray()
        return iterateLineSegments({p1, p2 in
            for rectLine in rectLines {
                if self.linesIntersection(line1P1: rectLine.p1, line1P2: rectLine.p2, line2P1: p1.screenLoc, line2P2: p2.screenLoc) != nil {
                    return true
                }
            }
            return nil
        }) ?? false
    }

    fileprivate func intersectsWithTrackerLine(_ rect: CGRect) -> Bool {
        
        guard let currentIntersection = currentIntersections.first else {return false}
        
        let rectLines = rect.asLinesArray()
        
        let line = toLine(currentIntersection)
        
        for rectLine in rectLines {
            if linesIntersection(line1P1: rectLine.p1, line1P2: rectLine.p2, line2P1: line.p1, line2P2: line.p2) != nil {
                return true
            }
        }
        
        return false
    }
   
    fileprivate func updateTrackerLineOnValidState(updateFunc: (_ view: UIView) -> ()) {
        if !self.chartPointsModels.isEmpty {
            if let view = chart?.contentView {
                updateFunc(view)
            }
        }
    }
    
    /// f: function to be applied to each segment in the lines defined by p1, p2. Returns an object of type U to exit, returning it from the outer function, or nil to continue
    fileprivate func iterateLineSegments<U>(_ f: (_ p1: ChartPointLayerModel<T>, _ p2: ChartPointLayerModel<T>) -> U?) -> U? {
        for line in lineModels {
            guard !line.isEmpty else {continue}
            
            for i in 0..<(line.count - 1) {
                let m1 = line[i]
                let m2 = line[i + 1]
                
                if let res = f(m1, m2) {
                    return res
                }
            }
        }
        return nil
    }
    
    fileprivate func updateTrackerLine(touchPoint: CGPoint) {
        
        self.updateTrackerLineOnValidState{(view) in
            
            let constantX = touchPoint.x
            
            let touchlineP1 = CGPoint(x: constantX, y: 0)
            let touchlineP2 = CGPoint(x: constantX, y: view.frame.size.height)
            
            var intersections: [CGPoint] = []
            
            
            let _: Any? = self.iterateLineSegments({p1, p2 in
                if let intersection = self.linesIntersection(line1P1: touchlineP1, line1P2: touchlineP2, line2P1: p1.screenLoc, line2P2: p2.screenLoc) {
                    intersections.append(intersection)
                }
                return nil
            })

            
            if !intersections.isEmpty {
            
                self.currentIntersections = self.settings.selectNearest ? touchPoint.nearest(intersections).map{[$0.point]} ?? [] : intersections
                self.isTracking = true
                
                if self.chartPointsModels.count > 1 {
                 
                    let chartPoints: [ChartPointWithScreenLoc<T>] = intersections.map {intersection in
                        
                        // the charpoints as well as the touch (-> intersection) use global coordinates, to draw in drawer container we have to translate to its coordinates
                        let trans = self.globalToDrawersContainerCoordinates(intersection)!
                        
                        let zoomedAxisX = self.xAxis.firstVisibleScreen - self.xAxis.firstScreen + trans.x
                        let zoomedAxisY = self.yAxis.lastVisibleScreen - self.yAxis.lastScreen + trans.y
                        
                        let xScalar = self.xAxis.innerScalarForScreenLoc(zoomedAxisX)
                        let yScalar = self.yAxis.innerScalarForScreenLoc(zoomedAxisY)
                        
                        let dummyModel = self.chartPointsModels[0]
                        let x = dummyModel.chartPoint.x.copy(xScalar)
                        let y = dummyModel.chartPoint.y.copy(yScalar)
                        
                        let chartPoint = T(x: x, y: y)
             
                        return ChartPointWithScreenLoc<T>(chartPoint: chartPoint, screenLoc: intersection)
                    }
                    
                    self.positionUpdateHandler?(chartPoints)
                }
                
            } else {
                self.clearIntersections()
            }
        }
    }

    fileprivate func toLine(_ intersection: CGPoint) -> (p1: CGPoint, p2: CGPoint) {
        return (p1: CGPoint(x: intersection.x, y: 0), p2: CGPoint(x: intersection.x, y: 10000000))
    }
    
    override open func chartDrawersContentViewDrawing(context: CGContext, chart: Chart, view: UIView) {

        guard let firstIntersection = currentIntersections.first else {return}

        
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2)

        let coords = globalToDrawersContainerCoordinates(firstIntersection)!
        let line = toLine(coords)
        
        context.move(to: CGPoint(x: line.p1.x, y: line.p1.y))
        context.addLine(to: CGPoint(x: line.p2.x, y: line.p2.y))

        context.strokePath()
        
        if let thumbSettings = settings.thumbSettings {
            
            for intersection in currentIntersections {
                let coords = globalToDrawersContainerCoordinates(intersection)!
                context.setStrokeColor(UIColor.black.cgColor)
                context.strokeEllipse(in: CGRect(x: coords.x - thumbSettings.thumbSize / 2, y: coords.y - thumbSettings.thumbSize / 2, width: thumbSettings.thumbSize, height: thumbSettings.thumbSize))
            }
        }
    }
    
    open override func handlePanStart(_ location: CGPoint) {
        guard let localLocation = toLocalCoordinates(location) else {return}
        
        updateChartPointsScreenLocations()
        
        let surroundingRect = localLocation.surroundingRect(30)
        
        if intersectsWithChartPointLines(surroundingRect) || intersectsWithTrackerLine(surroundingRect) {
            isTracking = true
        } else {
            clearIntersections()
        }
    }
    
    fileprivate func clearIntersections() {
        currentIntersections = []
        positionUpdateHandler?([])
    }
    
    open override func processPan(location: CGPoint, deltaX: CGFloat, deltaY: CGFloat, isGesture: Bool, isDeceleration: Bool) -> Bool {
        guard let localLocation = toLocalCoordinates(location) else {return false}
        
        if isTracking {
            updateTrackerLine(touchPoint: localLocation)
            chart?.drawersContentView.setNeedsDisplay()
            return true
        } else {
            return false
        }
    }
    
    open override func handleGlobalTap(_ location: CGPoint) -> Any? {
        guard let localLocation = toLocalCoordinates(location) else {return nil}
        
        updateChartPointsScreenLocations()
        
        updateTrackerLine(touchPoint: localLocation)
        chart?.drawersContentView.setNeedsDisplay()

        return nil
    }
    
    open override func handlePanEnd() {
        isTracking = false
    }
    
    open override func handleZoomEnd() {
        super.handleZoomEnd()
//        updateChartPointsScreenLocations()
    }
    
    open override func modelLocToScreenLoc(x: Double) -> CGFloat {
        return xAxis.screenLocForScalar(x) - (chart?.containerFrame.origin.x ?? 0)
    }
    
    open override func modelLocToScreenLoc(y: Double) -> CGFloat {
        return yAxis.screenLocForScalar(y) - (chart?.containerFrame.origin.y ?? 0)
    }
    
    open override func zoom(_ scaleX: CGFloat, scaleY: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        chart?.drawersContentView.setNeedsDisplay()
        
        clearIntersections()
    }
    
    open override func zoom(_ x: CGFloat, y: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        super.zoom(x, y: y, centerX: centerX, centerY: centerY)
        clearIntersections()
        chart?.drawersContentView.setNeedsDisplay()
    }
    
    open override func pan(_ deltaX: CGFloat, deltaY: CGFloat) {
        super.pan(deltaX, deltaY: deltaY)
        chart?.drawersContentView.setNeedsDisplay()
    }
}
