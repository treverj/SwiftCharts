//
//  ChartStackedBarsLayer.swift
//  Examples
//
//  Created by ischuetz on 15/05/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

public typealias ChartStackedBarItemModel = (quantity: Double, bgColor: UIColor)

open class ChartStackedBarModel: ChartBarModel {

    let items: [ChartStackedBarItemModel]
    
    public init(constant: ChartAxisValue, start: ChartAxisValue, items: [ChartStackedBarItemModel]) {
        self.items = items

        let axisValue2Scalar = items.reduce(start.scalar) {sum, item in
            sum + item.quantity
        }
        let axisValue2 = start.copy(axisValue2Scalar)
        
        super.init(constant: constant, axisValue1: start, axisValue2: axisValue2)
    }
    
    lazy var totalQuantity: Double = {
        return self.items.reduce(0) {total, item in
            total + item.quantity
        }
    }()
}


class ChartStackedBarsViewGenerator<T: ChartStackedBarModel>: ChartBarsViewGenerator<T, ChartPointViewBarStacked> {
    
    fileprivate typealias FrameBuilder = (_ barModel: ChartStackedBarModel, _ item: ChartStackedBarItemModel, _ currentTotalQuantity: Double) -> (frame: ChartPointViewBarStackedFrame, length: CGFloat)
    
    override init(horizontal: Bool, layer: ChartCoordsSpaceLayer, barWidth: CGFloat) {
        super.init(horizontal: horizontal, layer: layer, barWidth: barWidth)
    }
    
    override func generateView(_ barModel: T, constantScreenLoc constantScreenLocMaybe: CGFloat? = nil, bgColor: UIColor? = nil, animDuration: Float, chart: Chart? = nil) -> ChartPointViewBarStacked {
        
        let constantScreenLoc = constantScreenLocMaybe ?? self.constantScreenLoc(barModel)
        
        let frameBuilder: FrameBuilder = {
            switch self.horizontal {
            case true:
                return {barModel, item, currentTotalQuantity in
                    let p0 = self.layer.modelLocToScreenLoc(x: currentTotalQuantity)
                    let p1 = self.layer.modelLocToScreenLoc(x: currentTotalQuantity + item.quantity)
                    let length = p1 - p0
                    let barLeftScreenLoc = self.layer.modelLocToScreenLoc(x: length > 0 ? barModel.axisValue1.scalar : barModel.axisValue2.scalar)
                    
                    return (frame: ChartPointViewBarStackedFrame(rect:
                        CGRect(
                            x: p0 - barLeftScreenLoc,
                            y: 0,
                            width: length,
                            height: self.barWidth), color: item.bgColor), length: length)
                }
            case false:
                return {barModel, item, currentTotalQuantity in
                    let p0 = self.layer.modelLocToScreenLoc(y: currentTotalQuantity)
                    let p1 = self.layer.modelLocToScreenLoc(y: currentTotalQuantity + item.quantity)
                    let length = p1 - p0
                    let barTopScreenLoc = self.layer.modelLocToScreenLoc(y: length > 0 ? barModel.axisValue1.scalar : barModel.axisValue2.scalar)
                    
                    return (frame: ChartPointViewBarStackedFrame(rect:
                        CGRect(
                            x: 0,
                            y: p0 - barTopScreenLoc,
                            width: self.barWidth,
                            height: length), color: item.bgColor), length: length)
                }
            }
        }()
        
        
        let stackFrames = barModel.items.reduce((currentTotalQuantity: barModel.axisValue1.scalar, currentTotalLength: CGFloat(0), frames: Array<ChartPointViewBarStackedFrame>())) {tuple, item in
            let frameWithLength = frameBuilder(barModel, item, tuple.currentTotalQuantity)
            return (currentTotalQuantity: tuple.currentTotalQuantity + item.quantity, currentTotalLength: tuple.currentTotalLength + frameWithLength.length, frames: tuple.frames + [frameWithLength.frame])
        }
        
        let viewPoints = self.viewPoints(barModel, constantScreenLoc: constantScreenLoc)
        
        return ChartPointViewBarStacked(p1: viewPoints.p1, p2: viewPoints.p2, width: self.barWidth, stackFrames: stackFrames.frames, animDuration: animDuration)
    }
    
}

public struct ChartTappedBarStacked {
    public let model: ChartStackedBarModel
    public let barView: ChartPointViewBarStacked
    public let stackedItemModel: ChartStackedBarItemModel
    public let stackedItemView: UIView
    public let stackedItemViewFrameRelativeToBarParent: CGRect
    public let stackedItemIndex: Int
    public let layer: ChartCoordsSpaceLayer
}

open class ChartStackedBarsLayer: ChartCoordsSpaceLayer {
    fileprivate let barModels: [ChartStackedBarModel]
    fileprivate let horizontal: Bool
    fileprivate let barWidth: CGFloat
    fileprivate let animDuration: Float

    fileprivate var barViews: [UIView] = []

    fileprivate let stackFrameSelectionViewUpdater: ChartViewSelector?
    fileprivate let barSelectionViewUpdater: ChartViewSelector?
    
    fileprivate var tapHandler: ((ChartTappedBarStacked) -> Void)?
    
    public init(xAxis: ChartAxis, yAxis: ChartAxis, innerFrame: CGRect, barModels: [ChartStackedBarModel], horizontal: Bool = false, barWidth: CGFloat, animDuration: Float, stackFrameSelectionViewUpdater: ChartViewSelector? = nil, barSelectionViewUpdater: ChartViewSelector? = nil, tapHandler: ((ChartTappedBarStacked) -> Void)? = nil) {
        self.barModels = barModels
        self.horizontal = horizontal
        self.barWidth = barWidth
        self.animDuration = animDuration
        self.stackFrameSelectionViewUpdater = stackFrameSelectionViewUpdater
        self.barSelectionViewUpdater = barSelectionViewUpdater
        self.tapHandler = tapHandler
        super.init(xAxis: xAxis, yAxis: yAxis)
    }
    
    open override func chartInitialized(chart: Chart) {
        super.chartInitialized(chart: chart)
        
        let barsGenerator = ChartStackedBarsViewGenerator(horizontal: self.horizontal, layer: self, barWidth: self.barWidth)
        
        for barModel in barModels {
            let barView = barsGenerator.generateView(barModel, animDuration: isTransform ? 0 : animDuration, chart: self.chart)
            barView.selectionViewUpdater = barSelectionViewUpdater
            barView.stackFrameSelectionViewUpdater = stackFrameSelectionViewUpdater
            barView.stackedTapHandler = {[weak self] tappedStackedBar in guard let weakSelf = self else {return}
                let stackFrameIndex = tappedStackedBar.stackFrame.index
                let itemModel = barModel.items[stackFrameIndex]
                let tappedStacked = ChartTappedBarStacked(model: barModel, barView: barView, stackedItemModel: itemModel, stackedItemView: tappedStackedBar.stackFrame.view, stackedItemViewFrameRelativeToBarParent: tappedStackedBar.stackFrame.viewFrameRelativeToBarSuperview,  stackedItemIndex: stackFrameIndex, layer: weakSelf)
                weakSelf.tapHandler?(tappedStacked)
            }
            barViews.append(barView)
            chart.addSubview(barView)
        }
    }
}
