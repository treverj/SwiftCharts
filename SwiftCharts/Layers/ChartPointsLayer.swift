//
//  ChartPointsLayer.swift
//  SwiftCharts
//
//  Created by ischuetz on 25/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

public struct ChartPointLayerModel<T: ChartPoint>: CustomDebugStringConvertible {
    public let chartPoint: T
    public let index: Int
    public var screenLoc: CGPoint
    
    init(chartPoint: T, index: Int, screenLoc: CGPoint) {
        self.chartPoint = chartPoint
        self.index = index
        self.screenLoc = screenLoc
    }
    
    func copy(_ chartPoint: T? = nil, index: Int? = nil, screenLoc: CGPoint? = nil) -> ChartPointLayerModel<T> {
        return ChartPointLayerModel(
            chartPoint: chartPoint ?? self.chartPoint,
            index: index ?? self.index,
            screenLoc: screenLoc ?? self.screenLoc
        )
    }
    
    public var debugDescription: String {
        return "chartPoint: \(chartPoint), index: \(index), screenLoc: \(screenLoc)"
    }
}

public struct TappedChartPointLayerModel<T: ChartPoint> {
    public let model: ChartPointLayerModel<T>
    public let distance: CGFloat
    
    init(model: ChartPointLayerModel<T>, distance: CGFloat) {
        self.model = model
        self.distance = distance
    }
}


public struct TappedChartPointLayerModels<T: ChartPoint> {
    public let models: [TappedChartPointLayerModel<T>]
    public let layer: ChartPointsLayer<T>
    
    init(models: [TappedChartPointLayerModel<T>], layer: ChartPointsLayer<T>) {
        self.models = models
        self.layer = layer
    }
}

public struct ChartPointsTapSettings<T: ChartPoint> {
    public let radius: CGFloat
    let handler: ((TappedChartPointLayerModels<T>) -> Void)?
    
    public init(radius: CGFloat = 30, handler: ((TappedChartPointLayerModels<T>) -> Void)? = nil) {
        self.radius = radius
        self.handler = handler
    }
}

open class ChartPointsLayer<T: ChartPoint>: ChartCoordsSpaceLayer {

    open internal(set) var chartPointsModels: [ChartPointLayerModel<T>] = []
    
    fileprivate let displayDelay: Float
    
    open var chartPointScreenLocs: [CGPoint] {
        return self.chartPointsModels.map{$0.screenLoc}
    }
    
    fileprivate let chartPoints: [T]

    fileprivate let tapSettings: ChartPointsTapSettings<T>?
    
    public init(xAxis: ChartAxis, yAxis: ChartAxis, chartPoints: [T], displayDelay: Float = 0, tapSettings: ChartPointsTapSettings<T>? = nil) {
        self.chartPoints = chartPoints
        self.displayDelay = displayDelay
        self.tapSettings = tapSettings
        
        super.init(xAxis: xAxis, yAxis: yAxis)
    }

    open override func handleGlobalTap(_ location: CGPoint) -> Any? {
        guard let tapSettings = tapSettings, let localCenter = toLocalCoordinates(location) else {return nil}
        var models: [TappedChartPointLayerModel<T>] = []
        for chartPointModel in chartPointsModels {
            let transformedScreenLoc = modelLocToScreenLoc(x: chartPointModel.chartPoint.x.scalar, y: chartPointModel.chartPoint.y.scalar)
            let distance = transformedScreenLoc.distance(localCenter)
            if distance < tapSettings.radius {
                models.append(TappedChartPointLayerModel(model: chartPointModel.copy(screenLoc: containerToGlobalScreenLoc(chartPointModel.chartPoint)), distance: distance))
            }
        }
        
        let tappedModels = TappedChartPointLayerModels(models: models, layer: self)
        
        tapSettings.handler?(tappedModels)
        
        return tappedModels
    }
    
    func toLocalCoordinates(_ globalPoint: CGPoint) -> CGPoint? {
        return globalPoint
    }
    
    override open func chartInitialized(chart: Chart) {
        super.chartInitialized(chart: chart)
        
        initChartPointModels()
        
        if self.isTransform || self.displayDelay == 0 {
            self.display(chart: chart)
        } else {
            DispatchQueue.main.asyncAfter(deadline: ChartTimeUtils.toDispatchTime(self.displayDelay)) {() -> Void in
                self.display(chart: chart)
            }
        }
    }
    
    func initChartPointModels() {
        chartPointsModels = generateChartPointModels(chartPoints)
    }
    
    func generateChartPointModels(_ chartPoints: [T]) -> [ChartPointLayerModel<T>] {
        return chartPoints.enumerated().map {index, chartPoint in
            ChartPointLayerModel(chartPoint: chartPoint, index: index, screenLoc: modelLocToScreenLoc(x: chartPoint.x.scalar, y: chartPoint.y.scalar))
        }
    }
    
    func display(chart: Chart) {}
    
    open override func handleAxisInnerFrameChange(_ xLow: ChartAxisLayerWithFrameDelta?, yLow: ChartAxisLayerWithFrameDelta?, xHigh: ChartAxisLayerWithFrameDelta?, yHigh: ChartAxisLayerWithFrameDelta?) {
        super.handleAxisInnerFrameChange(xLow, yLow: yLow, xHigh: xHigh, yHigh: yHigh)

        chartPointsModels = chartPoints.enumerated().map {index, chartPoint in
            return ChartPointLayerModel(chartPoint: chartPoint, index: index, screenLoc: modelLocToScreenLoc(x: chartPoint.x.scalar, y: chartPoint.y.scalar))
        }
    }
    
    open func chartPointScreenLoc(_ chartPoint: ChartPoint) -> CGPoint {
        return self.modelLocToScreenLoc(x: chartPoint.x.scalar, y: chartPoint.y.scalar)
    }
    
    open func chartPointsForScreenLoc(_ screenLoc: CGPoint) -> [T] {
        return self.filterChartPoints { $0 == screenLoc }
    }
    
    open func chartPointsForScreenLocX(_ x: CGFloat) -> [T] {
        return self.filterChartPoints { $0.x =~ x }
    }
    
    open func chartPointsForScreenLocY(_ y: CGFloat) -> [T] {
        return self.filterChartPoints { $0.y =~ y }

    }

    // smallest screen space between chartpoints on x axis
    open lazy var minXScreenSpace: CGFloat = {
        return self.minAxisScreenSpace{$0.x}
    }()
    
    // smallest screen space between chartpoints on y axis
    open lazy var minYScreenSpace: CGFloat = {
        return self.minAxisScreenSpace{$0.y}
    }()
    
    fileprivate func minAxisScreenSpace(dimPicker: (CGPoint) -> CGFloat) -> CGFloat {
        return self.chartPointsModels.reduce((CGFloat.greatestFiniteMagnitude, -CGFloat.greatestFiniteMagnitude)) {tuple, viewWithChartPoint in
            let minSpace = tuple.0
            let previousScreenLoc = tuple.1
            return (min(minSpace, abs(dimPicker(viewWithChartPoint.screenLoc) - previousScreenLoc)), dimPicker(viewWithChartPoint.screenLoc))
        }.0
    }
    
    fileprivate func filterChartPoints(_ includePoint: (CGPoint) -> Bool) -> [T] {
        return self.chartPointsModels.reduce(Array<T>()) { includedPoints, chartPointModel in
            let chartPoint = chartPointModel.chartPoint
            if includePoint(self.chartPointScreenLoc(chartPoint)) {
                return includedPoints + [chartPoint]
            } else {
                return includedPoints
            }
        }
    }
    
    func updateChartPointsScreenLocations() {
        chartPointsModels = updateChartPointsScreenLocations(chartPointsModels)
    }
    
    func updateChartPointsScreenLocations(_ chartPointsModels: [ChartPointLayerModel<T>]) -> [ChartPointLayerModel<T>] {
        var chartPointsModelsVar = chartPointsModels
        for i in 0..<chartPointsModelsVar.count {
            let chartPointModel = chartPointsModelsVar[i]
            chartPointsModelsVar[i].screenLoc = CGPoint(x: xAxis.screenLocForScalar(chartPointModel.chartPoint.x.scalar), y: yAxis.screenLocForScalar(chartPointModel.chartPoint.y.scalar))
        }
        return chartPointsModelsVar
    }
}
