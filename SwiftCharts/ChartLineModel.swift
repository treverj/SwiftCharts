//
//  ChartLineModel.swift
//  swift_charts
//
//  Created by ischuetz on 11/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

/// Models a line to be drawn in a chart based on an array of chart points.
public struct ChartLineModel<T: ChartPoint> {

    /// The array of chart points that the line should be drawn with. In a simple case this would be drawn as straight line segments connecting each point.
    let chartPoints: [T]

    /// The color that the line is drawn with
    let lineColor: UIColor

    /// The width of the line in points
    let lineWidth: CGFloat
    
    let lineJoin: LineJoin
    
    let lineCap: LineCap
    
    /// The duration in seconds of the animation that is run when the line appears
    let animDuration: Float

    /// The delay in seconds before the animation runs
    let animDelay: Float
    
    public init(chartPoints: [T], lineColor: UIColor, lineWidth: CGFloat = 1, lineJoin: LineJoin = .round, lineCap: LineCap = .round, animDuration: Float, animDelay: Float) {
        self.chartPoints = chartPoints
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.lineJoin = lineJoin
        self.lineCap = lineCap
        self.animDuration = animDuration
        self.animDelay = animDelay
    }

    /// The number of chart points in the model
    var chartPointsCount: Int {
        return self.chartPoints.count
    }
    
}
