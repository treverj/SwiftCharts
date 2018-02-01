//
//  ChartBarsLayer.swift
//  Examples
//
//  Created by ischuetz on 17/05/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

open class ChartBarModel {
    open let constant: ChartAxisValue
    open let axisValue1: ChartAxisValue
    open let axisValue2: ChartAxisValue
    open let bgColor: UIColor?

    /**
    - parameter constant:Value of coordinate which doesn't change between start and end of the bar - if the bar is horizontal, this is y, if it's vertical it's x.
    - parameter axisValue1:Start, variable coordinate.
    - parameter axisValue2:End, variable coordinate.
    - parameter bgColor:Background color of bar.
    */
    public init(constant: ChartAxisValue, axisValue1: ChartAxisValue, axisValue2: ChartAxisValue, bgColor: UIColor? = nil) {
        self.constant = constant
        self.axisValue1 = axisValue1
        self.axisValue2 = axisValue2
        self.bgColor = bgColor
    }
}

class ChartBarsViewGenerator<T: ChartBarModel, U: ChartPointViewBar> {
    let layer: ChartCoordsSpaceLayer
    let barWidth: CGFloat
    
    let horizontal: Bool
    
    init(horizontal: Bool, layer: ChartCoordsSpaceLayer, barWidth: CGFloat) {
        self.layer = layer
        self.horizontal = horizontal
        self.barWidth = barWidth
    }
    
    func viewPoints(_ barModel: T, constantScreenLoc: CGFloat) -> (p1: CGPoint, p2: CGPoint) {

        
        switch self.horizontal {
        case true:
            return (
                CGPoint(x: layer.modelLocToScreenLoc(x: barModel.axisValue1.scalar), y: constantScreenLoc),
                CGPoint(x: layer.modelLocToScreenLoc(x: barModel.axisValue2.scalar), y: constantScreenLoc))
        case false:
            return (
                CGPoint(x: constantScreenLoc, y: layer.modelLocToScreenLoc(y: barModel.axisValue1.scalar)),
                CGPoint(x: constantScreenLoc, y: layer.modelLocToScreenLoc(y: barModel.axisValue2.scalar)))
        }
    }
    
    func constantScreenLoc(_ barModel: T) -> CGFloat {
        return horizontal ? layer.modelLocToScreenLoc(y: barModel.constant.scalar) : layer.modelLocToScreenLoc(x: barModel.constant.scalar)
    }
    
    // constantScreenLoc: (screen) coordinate that is equal in p1 and p2 - for vertical bar this is the x coordinate, for horizontal bar this is the y coordinate
    func generateView(_ barModel: T, constantScreenLoc constantScreenLocMaybe: CGFloat? = nil, bgColor: UIColor?, animDuration: Float, chart: Chart? = nil) -> U {
        
        let constantScreenLoc = constantScreenLocMaybe ?? self.constantScreenLoc(barModel)
        
        let viewPoints = self.viewPoints(barModel, constantScreenLoc: constantScreenLoc)
        return U(p1: viewPoints.p1, p2: viewPoints.p2, width: self.barWidth, bgColor: bgColor, animDuration: animDuration)
    }
}


public struct ChartTappedBar {
    public let model: ChartBarModel
    public let view: ChartPointViewBar
    public let layer: ChartCoordsSpaceLayer
}

open class ChartBarsLayer: ChartCoordsSpaceLayer {
    fileprivate let bars: [ChartBarModel]
    fileprivate let barWidth: CGFloat
    fileprivate let horizontal: Bool
    fileprivate let animDuration: Float

    fileprivate var barViews: [UIView] = []
    
    fileprivate var tapHandler: ((ChartTappedBar) -> Void)?
    
    public init(xAxis: ChartAxis, yAxis: ChartAxis, bars: [ChartBarModel], horizontal: Bool = false, barWidth: CGFloat, animDuration: Float, tapHandler: ((ChartTappedBar) -> Void)? = nil) {
        self.bars = bars
        self.horizontal = horizontal
        self.barWidth = barWidth
        self.animDuration = animDuration
        self.tapHandler = tapHandler
        
        super.init(xAxis: xAxis, yAxis: yAxis)
    }
    
    open override func chartInitialized(chart: Chart) {
        super.chartInitialized(chart: chart)
        
        let barsGenerator = ChartBarsViewGenerator(horizontal: horizontal, layer: self, barWidth: barWidth)
        
        for barModel in bars {
            let barView = barsGenerator.generateView(barModel, bgColor: barModel.bgColor, animDuration: isTransform ? 0 : animDuration, chart: chart)
            barView.tapHandler = {[weak self] tappedBarView in guard let weakSelf = self else {return}
                weakSelf.tapHandler?(ChartTappedBar(model: barModel, view: tappedBarView, layer: weakSelf))
            }
        
            barViews.append(barView)
            chart.addSubview(barView)
        }
    }
}
