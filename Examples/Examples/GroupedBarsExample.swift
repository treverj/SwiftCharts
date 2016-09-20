//
//  GroupedBarsExample.swift
//  Examples
//
//  Created by ischuetz on 19/05/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftCharts

class GroupedBarsExample: UIViewController {

    fileprivate var chart: Chart?
    fileprivate var shadowView: UIView?
    fileprivate var lineView: UIView?

    fileprivate let dirSelectorHeight: CGFloat = 50

    fileprivate func barsChart(horizontal: Bool) -> Chart {
        let labelSettings = ChartLabelSettings(font: ExamplesDefaults.labelFont)
        
        let groupsData: [(title: String, [(min: Double, max: Double)])] = [
            ("A", [
                (0, 40),
                (0, 50),
                (0, 35)
                ]),
            ("B", [
                (0, 20),
                (0, 30),
                (0, 25)
                ]),
            ("C", [
                (0, 30),
                (0, 50),
                (0, 5)
                ]),
            ("D", [
                (0, 30),
                (0, 50),
                (0, 5)
                ]),
            ("E", [
                (0, 30),
                (0, 50),
                (0, 5)
                ]),
            ("F", [
                (0, 30),
                (0, 50),
                (0, 5)
                ]),
            ("G", [
                (0, 30),
                (0, 50),
                (0, 5)
                ]),
            ("H", [
                (0, 30),
                (0, 50),
                (0, 5)
                ]),
            ("I", [
                (0, 30),
                (0, 50),
                (0, 5)
                ]),
            ("J", [
                (0, 30),
                (0, 50),
                (0, 5)
                ]),
            ("K", [
                (0, 30),
                (0, 50),
                (0, 5)
                ]),
            ("L", [
                (0, 55),
                (0, 30),
                (0, 25)
                ])
        ]
        
        let groupColors = [UIColor.red.withAlphaComponent(0.6), UIColor.blue.withAlphaComponent(0.6), UIColor.green.withAlphaComponent(0.6)]
        
        let groups: [ChartPointsBarGroup] = groupsData.enumerated().map {index, entry in
            let constant = ChartAxisValueDouble(index)
            let bars = entry.1.enumerated().map {index, tuple in
                ChartBarModel(constant: constant, axisValue1: ChartAxisValueDouble(tuple.min), axisValue2: ChartAxisValueDouble(tuple.max), bgColor: groupColors[index])
            }
            return ChartPointsBarGroup(constant: constant, bars: bars)
        }
        
        let (axisValues1, axisValues2): ([ChartAxisValue], [ChartAxisValue]) = (
            stride(from: 0, through: 60, by: 5).map {ChartAxisValueDouble(Double($0), labelSettings: labelSettings)},
            [ChartAxisValueString(order: -1)] +
                groupsData.enumerated().map {index, tuple in ChartAxisValueString(tuple.0, order: index, labelSettings: labelSettings)} +
                [ChartAxisValueString(order: groupsData.count)]
        )
        let (xValues, yValues) = horizontal ? (axisValues1, axisValues2) : (axisValues2, axisValues1)
        
        let xModel = ChartAxisModel(axisValues: xValues, lineColor: UIColor.clear, axisTitleLabel: ChartAxisLabel(text: "Axis title", settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: "Axis title", settings: labelSettings.defaultVertical()))
        let frame = ExamplesDefaults.chartFrame(self.view.bounds)
        let chartFrame = self.chart?.frame ?? CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.height - self.dirSelectorHeight)
        
        let chartSettings = ExamplesDefaults.chartSettingsWithPanZoom

        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
        let (xAxisLayer, yAxisLayer, innerFrame) = (coordsSpace.xAxisLayer, coordsSpace.yAxisLayer, coordsSpace.chartInnerFrame)
        
        let groupsLayer = ChartGroupedPlainBarsLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, groups: groups, horizontal: horizontal, barWidth: 5, barSpacing: 0, groupSpacing: 30, animDuration: 0.5, selectionViewUpdater: nil)
        {tappedGroupBar in
            
            if ((self.shadowView == nil)){
                let test = UIView(frame: tappedGroupBar.layer.highlightLayer[tappedGroupBar.groupIndex])
                test.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                self.shadowView = test
                self.chart?.addSubview(self.shadowView!)
            }
            else {
                UIView.animate(withDuration: CFTimeInterval(0.1), delay: 0, options: .curveEaseOut, animations: {
                    self.shadowView?.frame = tappedGroupBar.layer.highlightLayer[tappedGroupBar.groupIndex]
                    self.view.layoutIfNeeded()
                    }, completion: nil)
//                self.shadowView?.frame = tappedGroupBar.layer.hightLayer[tappedGroupBar.groupIndex]
            }
          }
        
        
        // line layer
//        let lineChartPoints = 0.stride(through: groupsData.count+1, by: 1).map {ChartPoint(x: ChartAxisValueDouble($0-1), y: ChartAxisValueDouble(10))}
//        let lineModel = ChartLineModel(chartPoints: lineChartPoints, lineColor: UIColor.blackColor(), lineWidth: 2, animDuration: 0.5, animDelay: 1)
//        let lineLayer = ChartPointsLineLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, lineModels: [lineModel])
        
        let guidelinesHighlightLayerSettings = ChartGuideLinesDottedLayerSettings(linesColor: UIColor.black, linesWidth: 1, dotWidth: 4, dotSpacing: 4)
        let guidelinesHighlightLayer = ChartGuideLinesForValuesDottedLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, settings: guidelinesHighlightLayerSettings, axisValuesX: [], axisValuesY: [ChartAxisValueDouble(20)], title: "Protein", conflicts: 0)
        
        let guidelinesHighlightLayer2 = ChartGuideLinesForValuesDottedLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, settings: guidelinesHighlightLayerSettings, axisValuesX: [], axisValuesY: [ChartAxisValueDouble(19)], title: "Carbs", conflicts: 1)
        
        let lineX = yAxisLayer.frame.origin.x + yAxisLayer.frame.width - 1
        let lineY = yAxisLayer.frame.origin.y + 60
        let lineView = UIView(frame: CGRect(x: lineX, y: lineY, width: 2, height: yAxisLayer.frame.height))
        lineView.backgroundColor = UIColor.red
        self.lineView = lineView
        
        
        return Chart(
            frame: chartFrame,
            innerFrame: innerFrame,
            settings: chartSettings,
            layers: [
                xAxisLayer,
                yAxisLayer,
                groupsLayer,
                guidelinesHighlightLayer,
                guidelinesHighlightLayer2
//                lineLayer
            ]
        )
    }
    
    
    fileprivate func showChart(horizontal: Bool) {
        self.chart?.clearView()
        
        let chart = self.barsChart(horizontal: horizontal)
        self.view.addSubview(chart.view)
        self.chart = chart
        self.view.addSubview(self.lineView!)
    }
    
    override func viewDidLoad() {
        self.showChart(horizontal: false)
        if let chart = self.chart {
            let dirSelector = DirSelector(frame: CGRect(x: 0, y: chart.frame.origin.y + chart.frame.size.height, width: self.view.frame.size.width, height: self.dirSelectorHeight), controller: self)
            self.view.addSubview(dirSelector)
        }
    }
    
    class DirSelector: UIView {
        
        let horizontal: UIButton
        let vertical: UIButton
        
        weak var controller: GroupedBarsExample?
        
        fileprivate let buttonDirs: [UIButton : Bool]
        
        init(frame: CGRect, controller: GroupedBarsExample) {
            
            self.controller = controller
            
            self.horizontal = UIButton()
            self.horizontal.setTitle("Horizontal", for: UIControlState())
            self.vertical = UIButton()
            self.vertical.setTitle("Vertical", for: UIControlState())
            
            self.buttonDirs = [self.horizontal : true, self.vertical : false]
            
            super.init(frame: frame)
            
            self.addSubview(self.horizontal)
            self.addSubview(self.vertical)
            
            for button in [self.horizontal, self.vertical] {
                button.titleLabel?.font = ExamplesDefaults.fontWithSize(14)
                button.setTitleColor(UIColor.blue, for: UIControlState())
                button.addTarget(self, action: #selector(DirSelector.buttonTapped(_:)), for: .touchUpInside)
            }
        }
        
        func buttonTapped(_ sender: UIButton) {
            let horizontal = sender == self.horizontal ? true : false
            controller?.showChart(horizontal: horizontal)
        }
        
        override func didMoveToSuperview() {
            let views = [self.horizontal, self.vertical]
            for v in views {
                v.translatesAutoresizingMaskIntoConstraints = false
            }
            
            let namedViews = views.enumerated().map{index, view in
                ("v\(index)", view)
            }
            
            var viewsDict = Dictionary<String, UIView>()
            for namedView in namedViews {
                viewsDict[namedView.0] = namedView.1
            }
            
            let buttonsSpace: CGFloat = Env.iPad ? 20 : 10
            
            let hConstraintStr = namedViews.reduce("H:|") {str, tuple in
                "\(str)-(\(buttonsSpace))-[\(tuple.0)]"
            }
            
            let vConstraits = namedViews.flatMap {NSLayoutConstraint.constraints(withVisualFormat: "V:|[\($0.0)]", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict)}
            
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: hConstraintStr, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDict)
                + vConstraits)
        }
        
        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
