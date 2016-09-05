//
//  ChartGroupedBarsLayer.swift
//  Examples
//
//  Created by ischuetz on 19/05/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

public final class ChartPointsBarGroup<T: ChartBarModel> {
    let constant: ChartAxisValue
    let bars: [T]
    
    public init(constant: ChartAxisValue, bars: [T]) {
        self.constant = constant
        self.bars = bars
    }
}


public class ChartGroupedBarsLayer<T: ChartBarModel, U: ChartPointViewBar>: ChartCoordsSpaceLayer {

    private let groups: [ChartPointsBarGroup<ChartBarModel>]
    
    private let barWidth: CGFloat?
    private let barSpacing: CGFloat?
    private let groupSpacing: CGFloat?
    
    private let horizontal: Bool
    
    private let animDuration: Float

    private var barViews: [UIView] = []
    
    private let selectionViewUpdater: ChartViewSelector?
    
    public var highlightLayer: [CGRect] = []
    
    convenience init(xAxis: ChartAxis, yAxis: ChartAxis, groups: [ChartPointsBarGroup<ChartBarModel>], horizontal: Bool = false, barSpacing: CGFloat?, groupSpacing: CGFloat?, barWidth: CGFloat?, animDuration: Float) {
        self.init(xAxis: xAxis, yAxis: yAxis, groups: groups, horizontal: horizontal, barWidth: barWidth, barSpacing: barSpacing, groupSpacing: groupSpacing, animDuration: animDuration)
    }
    
    init(xAxis: ChartAxis, yAxis: ChartAxis, groups: [ChartPointsBarGroup<ChartBarModel>], horizontal: Bool = false, barWidth: CGFloat?, barSpacing: CGFloat?, groupSpacing: CGFloat?, animDuration: Float, selectionViewUpdater: ChartViewSelector? = nil) {
        self.groups = groups
        self.horizontal = horizontal
        self.barWidth = barWidth
        self.barSpacing = barSpacing
        self.groupSpacing = groupSpacing
        self.animDuration = animDuration
        self.selectionViewUpdater = selectionViewUpdater
        
        super.init(xAxis: xAxis, yAxis: yAxis)
    }
    
    func barsGenerator(barWidth barWidth: CGFloat, chart: Chart) -> ChartBarsViewGenerator<ChartBarModel, U> {
        fatalError("override")
    }
    
    public override func chartInitialized(chart chart: Chart) {
        super.chartInitialized(chart: chart)
        
        let axis = self.horizontal ? self.yAxis : self.xAxis
        let groupAvailableLength = (axis.screenLength  - (self.groupSpacing ?? 0) * CGFloat(self.groups.count)) / CGFloat(groups.count + 1)
        let maxBarCountInGroup = self.groups.reduce(CGFloat(0)) {maxCount, group in
            max(maxCount, CGFloat(group.bars.count))
        }
        
        
        let barWidth = self.barWidth ?? (((groupAvailableLength - ((self.barSpacing ?? 0) * (maxBarCountInGroup - 1))) / CGFloat(maxBarCountInGroup)))
        
        let barsGenerator = self.barsGenerator(barWidth: barWidth, chart: chart)
        
        let calculateConstantScreenLoc: (screenLocCalculator: Double -> CGFloat, index: Int, group: ChartPointsBarGroup<ChartBarModel>) -> CGFloat = {screenLocCalculator, index, group in
            let totalWidth = CGFloat(group.bars.count) * barWidth + ((self.barSpacing ?? 0) * (maxBarCountInGroup - 1))
            let groupCenter = screenLocCalculator(group.constant.scalar)
            let origin = groupCenter - totalWidth / 2
            return origin + CGFloat(index) * (barWidth + (self.barSpacing ?? 0)) + barWidth / 2
        }
        
        for (groupIndex, group) in self.groups.enumerate() {
            var barViewGroup: [U] = []
            for (barIndex, bar) in group.bars.enumerate() {
                
                let constantScreenLoc: CGFloat = {
                    if barsGenerator.horizontal {
                        return calculateConstantScreenLoc(screenLocCalculator: {self.modelLocToScreenLoc(y: $0)}, index: barIndex, group: group)
                    } else {
                        return calculateConstantScreenLoc(screenLocCalculator: {self.modelLocToScreenLoc(x: $0)}, index: barIndex, group: group)
                    }
                }()
                let barView = barsGenerator.generateView(bar, constantScreenLoc: constantScreenLoc, bgColor: bar.bgColor, animDuration: isTransform ? 0 : animDuration)
                configBarView(group, groupIndex: groupIndex, barIndex: barIndex, bar: bar, barView: barView)
                barViews.append(barView)
                chart.addSubview(barView)
                barViewGroup.append(barView)
            }
            
            
            let x = (barViewGroup.first?.frame.origin.x)! - 5
            let y = chart.contentFrame.origin.y
            let width = barViewGroup.reduce(0) { $0 + $1.frame.width } + 10
            let height = chart.frame.height
            highlightLayer.append(CGRectMake(x, y, width, height))
        }
    }
    
    func configBarView(group: ChartPointsBarGroup<ChartBarModel>, groupIndex: Int, barIndex: Int, bar: ChartBarModel, barView: U) {
        barView.selectionViewUpdater = selectionViewUpdater
    }
}


public struct ChartTappedGroupBar {
    public let tappedBar: ChartTappedBar
    public let group: ChartPointsBarGroup<ChartBarModel>
    public let groupIndex: Int
    public let barIndex: Int // in group
    public let layer: ChartGroupedBarsLayer<ChartBarModel, ChartPointViewBar>
}

public typealias ChartGroupedPlainBarsLayer = ChartGroupedPlainBarsLayer_<Any>
public class ChartGroupedPlainBarsLayer_<N>: ChartGroupedBarsLayer<ChartBarModel, ChartPointViewBar> {
    
    let tapHandler: (ChartTappedGroupBar -> Void)?
    
    public convenience init(xAxis: ChartAxis, yAxis: ChartAxis, groups: [ChartPointsBarGroup<ChartBarModel>], horizontal: Bool = false, barSpacing: CGFloat?, groupSpacing: CGFloat?, animDuration: Float, selectionViewUpdater: ChartViewSelector? = nil, tapHandler: (ChartTappedGroupBar -> Void)? = nil) {
        self.init(xAxis: xAxis, yAxis: yAxis, groups: groups, horizontal: horizontal, barWidth: nil, barSpacing: barSpacing, groupSpacing: groupSpacing, animDuration: animDuration, selectionViewUpdater: selectionViewUpdater, tapHandler: tapHandler)
    }
    
    public init(xAxis: ChartAxis, yAxis: ChartAxis, groups: [ChartPointsBarGroup<ChartBarModel>], horizontal: Bool, barWidth: CGFloat?, barSpacing: CGFloat?, groupSpacing: CGFloat?, animDuration: Float, selectionViewUpdater: ChartViewSelector? = nil, tapHandler: (ChartTappedGroupBar -> Void)? = nil) {
        self.tapHandler = tapHandler
        super.init(xAxis: xAxis, yAxis: yAxis, groups: groups, horizontal: horizontal, barWidth: barWidth, barSpacing: barSpacing, groupSpacing: groupSpacing, animDuration: animDuration, selectionViewUpdater: selectionViewUpdater)
    }
    
    override func barsGenerator(barWidth barWidth: CGFloat, chart: Chart) -> ChartBarsViewGenerator<ChartBarModel, ChartPointViewBar> {
        return ChartBarsViewGenerator(horizontal: self.horizontal, layer: self, barWidth: barWidth)
    }
    
    override func configBarView(group: ChartPointsBarGroup<ChartBarModel>, groupIndex: Int, barIndex: Int, bar: ChartBarModel, barView: ChartPointViewBar) {
        super.configBarView(group, groupIndex: groupIndex, barIndex: barIndex, bar: bar, barView: barView)
        
        barView.tapHandler = {[weak self] _ in guard let weakSelf = self else {return}
            let tappedBar = ChartTappedBar(model: bar, view: barView, layer: weakSelf)
            let tappedGroupBar = ChartTappedGroupBar(tappedBar: tappedBar, group: group, groupIndex: groupIndex, barIndex: barIndex, layer: weakSelf)
            weakSelf.tapHandler?(tappedGroupBar)
        }
        
    }
}


//public struct ChartTappedGroupBarStacked {
//    public let tappedBar: ChartTappedBarStacked
//    public letgroup: ChartPointsBarGroup<ChartStackedBarModel>
//    public let groupIndex: Int
//    public let barIndex: Int // in group
//}
//
//public typealias ChartGroupedStackedBarsLayer = ChartGroupedStackedBarsLayer_<Any>
//public class ChartGroupedStackedBarsLayer_<N>: ChartGroupedBarsLayer<ChartStackedBarModel, ChartPointViewBarStacked> {
//    
//    private let stackFrameSelectionViewUpdater: ChartViewSelector?
//    let tapHandler: (ChartTappedGroupBarStacked -> Void)?
//    
//    public convenience init(xAxis: ChartAxis, yAxis: ChartAxis, groups: [ChartPointsBarGroup<ChartStackedBarModel>], horizontal: Bool = false, barSpacing: CGFloat?, groupSpacing: CGFloat?, animDuration: Float, stackFrameSelectionViewUpdater: ChartViewSelector? = nil, barSelectionViewUpdater: ChartViewSelector? = nil, tapHandler: (ChartTappedGroupBarStacked -> Void)? = nil) {
//        self.init(xAxis: xAxis, yAxis: yAxis, groups: groups, horizontal: horizontal, barWidth: nil, barSpacing: barSpacing, groupSpacing: groupSpacing, animDuration: animDuration, stackFrameSelectionViewUpdater: stackFrameSelectionViewUpdater, barSelectionViewUpdater: barSelectionViewUpdater, tapHandler: tapHandler)
//    }
//    
//    public init(xAxis: ChartAxis, yAxis: ChartAxis, groups: [ChartPointsBarGroup<ChartStackedBarModel>], horizontal: Bool, barWidth: CGFloat?, barSpacing: CGFloat?, groupSpacing: CGFloat?, animDuration: Float, stackFrameSelectionViewUpdater: ChartViewSelector? = nil, barSelectionViewUpdater: ChartViewSelector? = nil, tapHandler: (ChartTappedGroupBarStacked -> Void)? = nil) {
//        self.stackFrameSelectionViewUpdater = stackFrameSelectionViewUpdater
//        self.tapHandler = tapHandler
//        super.init(xAxis: xAxis, yAxis: yAxis, groups: groups, horizontal: horizontal, barWidth: barWidth, barSpacing: barSpacing, groupSpacing: groupSpacing, animDuration: animDuration, selectionViewUpdater: barSelectionViewUpdater)
//    }
//    
//    override func barsGenerator(barWidth barWidth: CGFloat, chart: Chart) -> ChartBarsViewGenerator<ChartStackedBarModel, ChartPointViewBarStacked> {
//        return ChartStackedBarsViewGenerator(horizontal: horizontal, layer: self, barWidth: barWidth)
//    }
//    
//    override func configBarView(group: ChartPointsBarGroup<ChartStackedBarModel>, groupIndex: Int, barIndex: Int, bar: ChartStackedBarModel, barView: ChartPointViewBarStacked, tappedGroupView: UIView) {
//        barView.stackedTapHandler = {[weak self] tappedStackedBar in guard let weakSelf = self else {return}
//            let stackFrameIndex = tappedStackedBar.stackFrame.index
//            let itemModel = bar.items[stackFrameIndex]
//            let tappedStacked = ChartTappedBarStacked(model: bar, barView: barView, stackedItemModel: itemModel, stackedItemView: tappedStackedBar.stackFrame.view, stackedItemViewFrameRelativeToBarParent: tappedStackedBar.stackFrame.viewFrameRelativeToBarSuperview, stackedItemIndex: stackFrameIndex, layer: weakSelf)
//            let tappedGroupBar = ChartTappedGroupBarStacked(tappedBar: tappedStacked, group: group, groupIndex: groupIndex, barIndex: barIndex)
//            weakSelf.tapHandler?(tappedGroupBar)
//        }
//        barView.stackFrameSelectionViewUpdater = stackFrameSelectionViewUpdater
//    }
//}