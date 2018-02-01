//
//  ChartAxisYLayerDefault.swift
//  SwiftCharts
//
//  Created by ischuetz on 25/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

/// A ChartAxisLayer for Y axes
class ChartAxisYLayerDefault: ChartAxisLayerDefault {
    
    fileprivate var minCalculatedLabelWidth: CGFloat?
    fileprivate var maxCalculatedLabelWidth: CGFloat?
    
    override var origin: CGPoint {
        return CGPoint(x: offset, y: axis.lastScreen)
    }
    
    override var end: CGPoint {
        return CGPoint(x: offset, y: axis.firstScreen)
    }
    
    override var height: CGFloat {
        return axis.screenLength
    }
    
    override var visibleFrame: CGRect {
        return CGRect(x: offset, y: axis.lastVisibleScreen, width: width, height: axis.visibleScreenLength)
    }
    
    var labelsMaxWidth: CGFloat {
        let currentWidth: CGFloat = {
            if self.labelDrawers.isEmpty {
                return self.maxLabelWidth(self.currentAxisValues)
            } else {
                return self.labelDrawers.reduce(0) {maxWidth, labelDrawer in
                    return max(maxWidth, labelDrawer.drawers.reduce(0) {maxWidth, drawer in
                        max(maxWidth, drawer.size.width)
                    })
                }
            }}()
        
        
        let width: CGFloat = {
            switch labelSpaceReservationMode {
            case .minPresentedSize: return minCalculatedLabelWidth.maxOpt(currentWidth)
            case .maxPresentedSize: return maxCalculatedLabelWidth.maxOpt(currentWidth)
            case .fixed(let value): return value
            case .current: return currentWidth
            }
        }()
        
        if !currentAxisValues.isEmpty {
            let (min, max): (CGFloat, CGFloat) = (minCalculatedLabelWidth.minOpt(currentWidth), maxCalculatedLabelWidth.maxOpt(currentWidth))
            minCalculatedLabelWidth = min
            maxCalculatedLabelWidth = max
        }
        
        return width
    }
    
    override var width: CGFloat {
        return self.labelsMaxWidth + self.settings.axisStrokeWidth + self.settings.labelsToAxisSpacingY + self.settings.axisTitleLabelsToLabelsSpacing + self.axisTitleLabelsWidth
    }
    
    override var widthWithoutLabels: CGFloat {
        return self.settings.axisStrokeWidth + self.settings.labelsToAxisSpacingY + self.settings.axisTitleLabelsToLabelsSpacing + self.axisTitleLabelsWidth
    }
    
    override var heightWithoutLabels: CGFloat {
        return height
    }
    
    override func handleAxisInnerFrameChange(_ xLow: ChartAxisLayerWithFrameDelta?, yLow: ChartAxisLayerWithFrameDelta?, xHigh: ChartAxisLayerWithFrameDelta?, yHigh: ChartAxisLayerWithFrameDelta?) {
        super.handleAxisInnerFrameChange(xLow, yLow: yLow, xHigh: xHigh, yHigh: yHigh)
        
        if let xLow = xLow {
            axis.offsetFirstScreen(-xLow.delta)
            self.initDrawers()
        }
        
        if let xHigh = xHigh {
            axis.offsetLastScreen(xHigh.delta)
            self.initDrawers()
        }
        
    }
    
    override func generateAxisTitleLabelsDrawers(offset: CGFloat) -> [ChartLabelDrawer] {
        
        if let firstTitleLabel = self.axisTitleLabels.first {
            
            if self.axisTitleLabels.count > 1 {
                print("WARNING: No support for multiple definition labels on vertical axis. Using only first one.")
            }
            let axisLabel = firstTitleLabel
            let labelSize = axisLabel.text.size(axisLabel.settings.font)
            let axisLabelDrawer = ChartLabelDrawer(label: axisLabel, screenLoc: CGPoint(
                x: self.offset + offset,
                y: axis.lastScreenInit + ((axis.firstScreenInit - axis.lastScreenInit) / 2) - (labelSize.height / 2)))
            
            return [axisLabelDrawer]
            
        } else { // definitionLabels is empty
            return []
        }
    }
    
    override func generateDirectLabelDrawers(offset: CGFloat) -> [ChartAxisValueLabelDrawers] {
        
        var drawers: [ChartAxisValueLabelDrawers] = []
        
        let scalars = self.valuesGenerator.generate(self.axis)
        currentAxisValues = scalars
        for scalar in scalars {
            let labels = self.labelsGenerator.generate(scalar, axis: axis)
            let y = self.axis.screenLocForScalar(scalar)
            if let axisLabel = labels.first { // for now y axis supports only one label x value
                let labelSize = axisLabel.text.size(axisLabel.settings.font)
                let labelY = y - (labelSize.height / 2)
                let labelX = self.labelsX(offset: offset, labelWidth: labelSize.width, textAlignment: axisLabel.settings.textAlignment)
                let labelDrawer = ChartLabelDrawer(label: axisLabel, screenLoc: CGPoint(x: labelX, y: labelY))

                let labelDrawers = ChartAxisValueLabelDrawers(scalar, [labelDrawer])
                drawers.append(labelDrawers)
            }
        }
        return drawers
    }
    
    func labelsX(offset: CGFloat, labelWidth: CGFloat, textAlignment: ChartLabelTextAlignment) -> CGFloat {
        fatalError("override")
    }
    
    fileprivate func maxLabelWidth(_ axisLabels: [ChartAxisLabel]) -> CGFloat {
        return axisLabels.reduce(CGFloat(0)) {maxWidth, label in
            return max(maxWidth, label.text.width(label.settings.font))
        }
    }
    fileprivate func maxLabelWidth(_ axisValues: [Double]) -> CGFloat {
        return axisValues.reduce(CGFloat(0)) {maxWidth, value in
            let labels = self.labelsGenerator.generate(value, axis: axis)
            return max(maxWidth, maxLabelWidth(labels))
        }
    }
    
    override func zoom(_ x: CGFloat, y: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        axis.zoom(x, y: y, centerX: centerX, centerY: centerY)
        update()
        chart?.view.setNeedsDisplay()
    }
    
    override func pan(_ deltaX: CGFloat, deltaY: CGFloat) {
        axis.pan(deltaX, deltaY: deltaY)
        update()
        chart?.view.setNeedsDisplay()
    }
    
    override func zoom(_ scaleX: CGFloat, scaleY: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        axis.zoom(scaleX, scaleY: scaleY, centerX: centerX, centerY: centerY)
        update()
        chart?.view.setNeedsDisplay()
    }
}
