//
//  ChartGuideLinesLayer.swift
//  SwiftCharts
//
//  Created by ischuetz on 26/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

public class ChartGuideLinesLayerSettings {
    let linesColor: UIColor
    let linesWidth: CGFloat
    
    public init(linesColor: UIColor = UIColor.grayColor(), linesWidth: CGFloat = 0.3) {
        self.linesColor = linesColor
        self.linesWidth = linesWidth
    }
}

public class ChartGuideLinesDottedLayerSettings: ChartGuideLinesLayerSettings {
    let dotWidth: CGFloat
    let dotSpacing: CGFloat
    
    public init(linesColor: UIColor, linesWidth: CGFloat, dotWidth: CGFloat = 2, dotSpacing: CGFloat = 2) {
        self.dotWidth = dotWidth
        self.dotSpacing = dotSpacing
        super.init(linesColor: linesColor, linesWidth: linesWidth)
    }
}

public enum ChartGuideLinesLayerAxis {
    case X, Y, XAndY
}

public class ChartGuideLinesLayerAbstract<T: ChartGuideLinesLayerSettings>: ChartCoordsSpaceLayer {
    
    private let settings: T
    private let axis: ChartGuideLinesLayerAxis
    private let xAxisLayer: ChartAxisLayer
    private let yAxisLayer: ChartAxisLayer

    public init(xAxisLayer: ChartAxisLayer, yAxisLayer: ChartAxisLayer, axis: ChartGuideLinesLayerAxis = .XAndY, settings: T) {
        self.settings = settings
        self.axis = axis
        self.xAxisLayer = xAxisLayer
        self.yAxisLayer = yAxisLayer
        
        super.init(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis)
    }
    
    private func drawGuideline(context: CGContextRef, p1: CGPoint, p2: CGPoint) {
        fatalError("override")
    }
    
    override public func chartViewDrawing(context context: CGContextRef, chart: Chart) {
        let originScreenLoc = chart.containerFrame.origin
        let xScreenLocs = self.xAxisLayer.axisValuesScreenLocs
        let yScreenLocs = self.yAxisLayer.axisValuesScreenLocs
        
        if self.axis == .X || self.axis == .XAndY {
            for xScreenLoc in xScreenLocs {
                guard (!yAxisLayer.low || xScreenLoc > yAxisLayer.frame.maxX) && (yAxisLayer.low || xScreenLoc < yAxisLayer.frame.minX) else {continue}
                let x1 = xScreenLoc
                let y1 = originScreenLoc.y
                let x2 = x1
                let y2 = originScreenLoc.y + chart.containerFrame.height
                self.drawGuideline(context, p1: CGPointMake(x1, y1), p2: CGPointMake(x2, y2))
            }
        }
        
        if self.axis == .Y || self.axis == .XAndY {
            for yScreenLoc in yScreenLocs {
                guard (xAxisLayer.low || yScreenLoc > xAxisLayer.frame.maxY) && (!xAxisLayer.low || yScreenLoc < xAxisLayer.frame.minY) else {continue}
                let x1 = originScreenLoc.x
                let y1 = yScreenLoc
                let x2 = originScreenLoc.x + chart.containerFrame.width
                let y2 = y1
                self.drawGuideline(context, p1: CGPointMake(x1, y1), p2: CGPointMake(x2, y2))
            }
        }
    }
}

public typealias ChartGuideLinesLayer = ChartGuideLinesLayer_<Any>
public class ChartGuideLinesLayer_<N>: ChartGuideLinesLayerAbstract<ChartGuideLinesLayerSettings> {
    
    override public init(xAxisLayer: ChartAxisLayer, yAxisLayer: ChartAxisLayer, axis: ChartGuideLinesLayerAxis = .XAndY, settings: ChartGuideLinesLayerSettings) {
        super.init(xAxisLayer: xAxisLayer, yAxisLayer: yAxisLayer, axis: axis, settings: settings)
    }
    
    override private func drawGuideline(context: CGContextRef, p1: CGPoint, p2: CGPoint) {
        ChartDrawLine(context: context, p1: p1, p2: p2, width: self.settings.linesWidth, color: self.settings.linesColor)
    }
}

public typealias ChartGuideLinesDottedLayer = ChartGuideLinesDottedLayer_<Any>
public class ChartGuideLinesDottedLayer_<N>: ChartGuideLinesLayerAbstract<ChartGuideLinesDottedLayerSettings> {
    
    override public init(xAxisLayer: ChartAxisLayer, yAxisLayer: ChartAxisLayer, axis: ChartGuideLinesLayerAxis = .XAndY, settings: ChartGuideLinesDottedLayerSettings) {
        super.init(xAxisLayer: xAxisLayer, yAxisLayer: yAxisLayer, axis: axis, settings: settings)
    }
    
    override private func drawGuideline(context: CGContextRef, p1: CGPoint, p2: CGPoint) {
        ChartDrawDottedLine(context: context, p1: p1, p2: p2, width: self.settings.linesWidth, color: self.settings.linesColor, dotWidth: self.settings.dotWidth, dotSpacing: self.settings.dotSpacing)
    }
}


public class ChartGuideLinesForValuesLayerAbstract<T: ChartGuideLinesLayerSettings>: ChartCoordsSpaceLayer {
    
    private let settings: T
    private let axisValuesX: [ChartAxisValue]
    private let axisValuesY: [ChartAxisValue]
    private let title: String
    private let conflicts: CGFloat
    private var labelDrawn: Bool = false


    public init(xAxis: ChartAxis, yAxis: ChartAxis, settings: T, axisValuesX: [ChartAxisValue], axisValuesY: [ChartAxisValue], title:String, conflicts:CGFloat) {
        self.settings = settings
        self.axisValuesX = axisValuesX
        self.axisValuesY = axisValuesY
        self.title = title
        self.conflicts = conflicts
        super.init(xAxis: xAxis, yAxis: yAxis)
    }
    
    private func drawGuideline(context: CGContextRef, color: UIColor, width: CGFloat, p1: CGPoint, p2: CGPoint, dotWidth: CGFloat, dotSpacing: CGFloat) {
        ChartDrawDottedLine(context: context, p1: p1, p2: p2, width: width, color: color, dotWidth: dotWidth, dotSpacing: dotSpacing)
    }
    
    private func drawGuideline(context: CGContextRef, p1: CGPoint, p2: CGPoint) {
        fatalError("override")
    }
    
    override public func chartViewDrawing(context context: CGContextRef, chart: Chart) {
        let originScreenLoc = chart.containerFrame.origin
        
        for axisValue in self.axisValuesX {
            let screenLoc = self.xAxis.screenLocForScalar(axisValue.scalar)
            let x1 = screenLoc
            let y1 = originScreenLoc.y
            let x2 = x1
            let y2 = originScreenLoc.y + chart.containerFrame.height
            self.drawGuideline(context, p1: CGPointMake(x1, y1), p2: CGPointMake(x2, y2))

        }
        
        for axisValue in self.axisValuesY {
            let screenLoc = self.yAxis.screenLocForScalar(axisValue.scalar)
            let x1 = originScreenLoc.x
            let y1 = screenLoc
            let x2 = originScreenLoc.x + chart.containerFrame.width
            let y2 = y1
            self.drawGuideline(context, p1: CGPointMake(x1, y1), p2: CGPointMake(x2, y2))

        }
    }
}


public typealias ChartGuideLinesForValuesLayer = ChartGuideLinesForValuesLayer_<Any>
public class ChartGuideLinesForValuesLayer_<N>: ChartGuideLinesForValuesLayerAbstract<ChartGuideLinesLayerSettings> {
    
    public override init(xAxis: ChartAxis, yAxis: ChartAxis, settings: ChartGuideLinesLayerSettings, axisValuesX: [ChartAxisValue], axisValuesY: [ChartAxisValue], title: String, conflicts:CGFloat) {
        super.init(xAxis: xAxis, yAxis: yAxis, settings: settings, axisValuesX: axisValuesX, axisValuesY: axisValuesY, title:title, conflicts:conflicts)
    }
    
    override private func drawGuideline(context: CGContextRef, p1: CGPoint, p2: CGPoint) {
        ChartDrawLine(context: context, p1: p1, p2: p2, width: self.settings.linesWidth, color: self.settings.linesColor)
    }
}

public typealias ChartGuideLinesForValuesDottedLayer = ChartGuideLinesForValuesDottedLayer_<Any>
public class ChartGuideLinesForValuesDottedLayer_<N>: ChartGuideLinesForValuesLayerAbstract<ChartGuideLinesDottedLayerSettings> {
    
    public override init(xAxis: ChartAxis, yAxis: ChartAxis, settings: ChartGuideLinesDottedLayerSettings, axisValuesX: [ChartAxisValue], axisValuesY: [ChartAxisValue], title: String, conflicts:CGFloat) {
        super.init(xAxis: xAxis, yAxis: yAxis, settings: settings, axisValuesX: axisValuesX, axisValuesY: axisValuesY, title:title, conflicts:conflicts)
    }
    
    override private func drawGuideline(context: CGContextRef, p1: CGPoint, p2: CGPoint) {
        if (!self.labelDrawn) {
            let width: CGFloat = 40.0
            let height: CGFloat = 20.0
            let x = p1.x + ((width+1)*self.conflicts)
            let y = p1.y
            let label = UILabel(frame: CGRectMake(x, y, width, height))
            label.backgroundColor = UIColor.blackColor()
            label.textColor = UIColor.whiteColor()
            label.font = UIFont(name: "Arial", size: 10)
            label.text = self.title
            label.textAlignment = .Center
            self.chart?.view.addSubview(label)
            self.labelDrawn = true
        }
        ChartDrawDottedLine(context: context, p1: p1, p2: p2, width: self.settings.linesWidth, color: self.settings.linesColor, dotWidth: self.settings.dotWidth, dotSpacing: self.settings.dotSpacing)
    }
}

