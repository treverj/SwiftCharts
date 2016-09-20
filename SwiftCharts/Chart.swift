//
//  Chart.swift
//  SwiftCharts
//
//  Created by ischuetz on 25/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

/// ChartSettings allows configuration of the visual layout of a chart
open class ChartSettings {

    /// Empty space in points added to the leading edge of the chart
    open var leading: CGFloat = 0

    /// Empty space in points added to the top edge of the chart
    open var top: CGFloat = 0

    /// Empty space in points added to the trailing edge of the chart
    open var trailing: CGFloat = 0

    /// Empty space in points added to the bottom edge of the chart
    open var bottom: CGFloat = 0

    /// The spacing in points between axis labels when using multiple labels for each axis value. This is currently only supported with an X axis.
    open var labelsSpacing: CGFloat = 5

    /// The spacing in points between X axis labels and the X axis line
    open var labelsToAxisSpacingX: CGFloat = 5

    /// The spacing in points between Y axis labels and the Y axis line
    open var labelsToAxisSpacingY: CGFloat = 5

    open var spacingBetweenAxesX: CGFloat = 15

    open var spacingBetweenAxesY: CGFloat = 15

    /// The spacing in points between axis title labels and axis labels
    open var axisTitleLabelsToLabelsSpacing: CGFloat = 5

    /// The stroke width in points of the axis lines
    open var axisStrokeWidth: CGFloat = 1.0
    
    open var zoomPan = ChartSettingsZoomPan()
    
    public init() {}
}

open class ChartSettingsZoomPan {
    open var panEnabled = false
    
    open var zoomEnabled = false

    open var minZoomX: CGFloat?
    
    open var minZoomY: CGFloat?
    
    open var maxZoomX: CGFloat?
    
    open var maxZoomY: CGFloat?
    
    open var gestureMode: ChartZoomPanGestureMode = .max
    
}

public enum ChartZoomPanGestureMode {
    case onlyX // Only X axis is zoomed/panned
    case onlyY // Only Y axis is zoomed/panned
    case max // Only axis corresponding to dimension with max zoom/pan delta is zoomed/panned
    case both // Both axes are zoomed/panned
}

public protocol ChartDelegate {
    
    func onZoom(scaleX: CGFloat, scaleY: CGFloat, deltaX: CGFloat, deltaY: CGFloat, centerX: CGFloat, centerY: CGFloat, isGesture: Bool)
    
    func onPan(transX: CGFloat, transY: CGFloat, deltaX: CGFloat, deltaY: CGFloat, isGesture: Bool, isDeceleration: Bool)
    
    func onTap(_ models: [TappedChartPointLayerModels<ChartPoint>])
}

/// A Chart object is the highest level access to your chart. It has the view where all of the chart layers are drawn, which you can provide (useful if you want to position it as part of a storyboard or XIB), or it can be created for you.
open class Chart: Pannable, Zoomable {

    /// The view that the chart is drawn in
    open let view: ChartView

    open let containerView: UIView
    open let contentView: UIView
    open let drawersContentView: UIView

    /// The layers of the chart that are drawn in the view
    fileprivate let layers: [ChartLayer]

    open var delegate: ChartDelegate?

    open var transX: CGFloat {
        return contentFrame.minX
    }
    
    open var transY: CGFloat {
        return contentFrame.minY
    }

    open var scaleX: CGFloat {
        return contentFrame.width / containerFrame.width
    }
    
    open var scaleY: CGFloat {
        return contentFrame.height / containerFrame.height
    }
 
    open var maxScaleX: CGFloat? {
        return settings.zoomPan.maxZoomX
    }
    
    open var minScaleX: CGFloat? {
        return settings.zoomPan.minZoomX
    }
    
    open var maxScaleY: CGFloat? {
        return settings.zoomPan.maxZoomY
    }
    
    open var minScaleY: CGFloat? {
        return settings.zoomPan.minZoomY
    }
    
    fileprivate let settings: ChartSettings
    
    open var zoomPanSettings: ChartSettingsZoomPan {
        set {
            settings.zoomPan = zoomPanSettings
            configZoomPan(zoomPanSettings)
        } get {
            return settings.zoomPan
        }
    }
    
    /**
     Create a new Chart with a frame and layers. A new ChartBaseView will be created for you.

     - parameter innerFrame: Frame comprised by axes, where the chart displays content
     - parameter settings: Chart settings
     - parameter frame:  The frame used for the ChartBaseView
     - parameter layers: The layers that are drawn in the chart

     - returns: The new Chart
     */
    convenience public init(frame: CGRect, innerFrame: CGRect? = nil, settings: ChartSettings, layers: [ChartLayer]) {
        self.init(view: ChartBaseView(frame: frame), innerFrame: innerFrame, settings: settings, layers: layers)
    }

    /**
     Create a new Chart with a view and layers.

     
     - parameter innerFrame: Frame comprised by axes, where the chart displays content
     - parameter settings: Chart settings
     - parameter view:   The view that the chart will be drawn in
     - parameter layers: The layers that are drawn in the chart

     - returns: The new Chart
     */
    public init(view: ChartView, innerFrame: CGRect? = nil, settings: ChartSettings, layers: [ChartLayer]) {
        
        self.layers = layers
        
        self.view = view

        self.settings = settings
        
        let containerView = UIView(frame: innerFrame ?? view.bounds)
        
        let drawersContentView = ChartContentView(frame: containerView.bounds)
        drawersContentView.backgroundColor = UIColor.clear
        containerView.addSubview(drawersContentView)
        
        let contentView = ChartContentView(frame: containerView.bounds)
        contentView.backgroundColor = UIColor.clear
        containerView.addSubview(contentView)
        
        containerView.clipsToBounds = true
        view.addSubview(containerView)

        self.contentView = contentView
        self.drawersContentView = drawersContentView
        self.containerView = containerView
        contentView.chart = self
        drawersContentView.chart = self
        
        self.view.chart = self
        
        for layer in self.layers {
            layer.chartInitialized(chart: self)
        }
        
        self.view.setNeedsDisplay()
        
        configZoomPan(settings.zoomPan)
    }
    
    fileprivate func configZoomPan(_ settings: ChartSettingsZoomPan) {
        if settings.minZoomX != nil || settings.minZoomY != nil {
            zoom(scaleX: settings.minZoomX ?? 1, scaleY: settings.minZoomY ?? 1, anchorX: 0, anchorY: 0)
        }
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Adds a subview to the chart's content view

     - parameter view: The subview to add to the chart's content view
     */
    open func addSubview(_ view: UIView) {
        self.contentView.addSubview(view)
    }

    /// The frame of the chart's view
    open var frame: CGRect {
        return self.view.frame
    }

    open var containerFrame: CGRect {
        return containerView.frame
    }
    
    open var contentFrame: CGRect {
        return contentView.frame
    }
    
    /// The bounds of the chart's view
    open var bounds: CGRect {
        return self.view.bounds
    }

    /**
     Removes the chart's view from its superview
     */
    open func clearView() {
        self.view.removeFromSuperview()
    }

    open func update() {
        for layer in self.layers {
            layer.update()
        }
        self.view.setNeedsDisplay()
    }
 
    func notifyAxisInnerFrameChange(xLow: ChartAxisLayerWithFrameDelta? = nil, yLow: ChartAxisLayerWithFrameDelta? = nil, xHigh: ChartAxisLayerWithFrameDelta? = nil, yHigh: ChartAxisLayerWithFrameDelta? = nil) {
        for layer in layers {
            layer.handleAxisInnerFrameChange(xLow, yLow: yLow, xHigh: xHigh, yHigh: yHigh)
        }
        
        handleAxisInnerFrameChange(xLow, yLow: yLow, xHigh: xHigh, yHigh: yHigh)
    }
    
    fileprivate func handleAxisInnerFrameChange(_ xLow: ChartAxisLayerWithFrameDelta?, yLow: ChartAxisLayerWithFrameDelta?, xHigh: ChartAxisLayerWithFrameDelta?, yHigh: ChartAxisLayerWithFrameDelta?) {
        let previousContentFrame = contentView.frame
        
        // Resize container view
        containerView.frame = containerView.frame.insetBy(dx: yLow.deltaDefault0, dy: xHigh.deltaDefault0, dw: yHigh.deltaDefault0, dh: xLow.deltaDefault0)
        // Change dimensions of content view by total delta of container view
        contentView.frame = CGRect(x: contentView.frame.origin.x, y: contentView.frame.origin.y, width: contentView.frame.width - (yLow.deltaDefault0 + yHigh.deltaDefault0), height: contentView.frame.height - (xLow.deltaDefault0 + xHigh.deltaDefault0))

        // Scale contents of content view
        let widthChangeFactor = contentView.frame.width / previousContentFrame.width
        let heightChangeFactor = contentView.frame.height / previousContentFrame.height
        let frameBeforeScale = contentView.frame
        contentView.transform = CGAffineTransform(scaleX: contentView.transform.a * widthChangeFactor, y: contentView.transform.d * heightChangeFactor)
        contentView.frame = frameBeforeScale
    }
    
    open func onZoomStart(deltaX: CGFloat, deltaY: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        for layer in layers {
            layer.zoom(deltaX, y: deltaY, centerX: centerX, centerY: centerY)
        }
    }
    
    open func onZoomStart(scaleX: CGFloat, scaleY: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        for layer in layers {
            layer.zoom(scaleX, scaleY: scaleY, centerX: centerX, centerY: centerY)
        }
    }
    
    open func onZoomFinish(scaleX: CGFloat, scaleY: CGFloat, deltaX: CGFloat, deltaY: CGFloat, centerX: CGFloat, centerY: CGFloat, isGesture: Bool) {
        delegate?.onZoom(scaleX: scaleX, scaleY: scaleY, deltaX: deltaX, deltaY: deltaY, centerX: centerX, centerY: centerY, isGesture: isGesture)
    }
    
    open func onPanStart(deltaX: CGFloat, deltaY: CGFloat) {
        for layer in layers {
            layer.pan(deltaX, deltaY: deltaY)
        }
    }
    
    open func onPanStart(location: CGPoint) {
        for layer in layers {
            layer.handlePanStart(location)
        }
    }

    open func onPanEnd() {
        for layer in layers {
            layer.handlePanEnd()
        }
    }

    open func onZoomEnd() {
        for layer in layers {
            layer.handleZoomEnd()
        }
    }
    
    open func onPanFinish(transX: CGFloat, transY: CGFloat, deltaX: CGFloat, deltaY: CGFloat, isGesture: Bool, isDeceleration: Bool) {
        delegate?.onPan(transX: transX, transY: transY, deltaX: deltaX, deltaY: deltaY, isGesture: isGesture, isDeceleration: isDeceleration)
    }

    func onTap(_ location: CGPoint) {
        var models = [TappedChartPointLayerModels<ChartPoint>]()
        for layer in layers {
            if let chartPointsLayer = layer as? ChartPointsLayer {
                if let tappedModels = chartPointsLayer.handleGlobalTap(location) as? TappedChartPointLayerModels<ChartPoint> {
                    models.append(tappedModels)
                }
            } else {
                layer.handleGlobalTap(location)
            }
        }
        delegate?.onTap(models)
    }
    
    /**
     Draws the chart's layers in the chart view

     - parameter rect: The rect that needs to be drawn
     */
    fileprivate func drawRect(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {return}
        for layer in self.layers {
            layer.chartViewDrawing(context: context, chart: self)
        }
    }
    
    fileprivate func drawContentViewRect(_ rect: CGRect, sender: ChartContentView) {
        guard let context = UIGraphicsGetCurrentContext() else {return}
        if sender == drawersContentView {
            for layer in layers {
                layer.chartDrawersContentViewDrawing(context: context, chart: self, view: sender)
            }
        } else if sender == contentView {
            for layer in layers {
                layer.chartContentViewDrawing(context: context, chart: self)
            }
            self.drawersContentView.setNeedsDisplay()
        }
    }
    
    func allowPan(location: CGPoint, deltaX: CGFloat, deltaY: CGFloat, isGesture: Bool, isDeceleration: Bool) -> Bool {
        var someLayerProcessedPan = false
        for layer in self.layers {
            if layer.processPan(location: location, deltaX: deltaX, deltaY: deltaY, isGesture: isGesture, isDeceleration: isDeceleration) {
                someLayerProcessedPan = true
            }
        }
        return !someLayerProcessedPan
    }
    
    func allowZoom(deltaX: CGFloat, deltaY: CGFloat, anchorX: CGFloat, anchorY: CGFloat) -> Bool {
        var someLayerProcessedZoom = false
        for layer in self.layers {
            if layer.processZoom(deltaX: deltaX, deltaY: deltaY, anchorX: anchorX, anchorY: anchorY) {
                someLayerProcessedZoom = true
            }
        }
        return !someLayerProcessedZoom
    }
}


open class ChartContentView: UIView {
    
    weak var chart: Chart?
    
    override open func draw(_ rect: CGRect) {
        self.chart?.drawContentViewRect(rect, sender: self)
    }
}

/// A UIView subclass for drawing charts
open class ChartBaseView: ChartView {
    
    override open func draw(_ rect: CGRect) {
        self.chart?.drawRect(rect)
    }
}

open class ChartView: UIView, UIGestureRecognizerDelegate {
    
    /// The chart that will be drawn in this view
    weak var chart: Chart?
    
    fileprivate var lastPanTranslation: CGPoint?
    fileprivate var isPanningX: Bool? // true: x, false: y
    
    fileprivate var pinchRecognizer: UIPinchGestureRecognizer?
    fileprivate var panRecognizer: UIPanGestureRecognizer?
    fileprivate var tapRecognizer: UITapGestureRecognizer?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.sharedInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.sharedInit()
    }
    
    func initRecognizers() {
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(ChartView.onPinch(_:)))
        pinchRecognizer.delegate = self
        addGestureRecognizer(pinchRecognizer)
        self.pinchRecognizer = pinchRecognizer
    
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ChartView.onPan(_:)))
        panRecognizer.delegate = self
        addGestureRecognizer(panRecognizer)
        self.panRecognizer = panRecognizer
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChartView.onTap(_:)))
        tapRecognizer.delegate = self
        tapRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(tapRecognizer)
        self.tapRecognizer = tapRecognizer
    }
    
    /**
     Initialization code shared between all initializers
     */
    func sharedInit() {
        self.backgroundColor = UIColor.clear
        initRecognizers()
    }
    
    @objc func onPinch(_ sender: UIPinchGestureRecognizer) {
        
        guard let chartSettings = chart?.settings , chartSettings.zoomPan.zoomEnabled else {return}
        guard sender.numberOfTouches > 1 else {return}
        
        switch sender.state {
        case .began: fallthrough
        case .changed:
            let center = sender.location(in: self)
            
            let x = abs(sender.location(in: self).x - sender.location(ofTouch: 1, in: self).x)
            let y = abs(sender.location(in: self).y - sender.location(ofTouch: 1, in: self).y)
            
            let (deltaX, deltaY): (CGFloat, CGFloat) = {
                switch chartSettings.zoomPan.gestureMode {
                case .onlyX: return (sender.scale, 1)
                case .onlyY: return (1, sender.scale)
                case .max: return x > y ? (sender.scale, 1) : (1, sender.scale)
                case .both:
                    // calculate scale x and scale y
                    let (absMax, absMin) = x > y ? (abs(x), abs(y)) : (abs(y), abs(x))
                    let minScale = (absMin * (sender.scale - 1) / absMax) + 1
                    return x > y ? (sender.scale, minScale) : (minScale, sender.scale)
                }
            }()
            
            chart?.zoom(deltaX: deltaX, deltaY: deltaY, centerX: center.x, centerY: center.y, isGesture: true)
            
        case .ended: chart?.onZoomEnd()
        case .cancelled: chart?.onZoomEnd()
        case .failed: fallthrough
        case .possible: break
        }
        
        sender.scale = 1.0
    }
    
    @objc func onPan(_ sender: UIPanGestureRecognizer) {
        
        guard let chartSettings = chart?.settings , chartSettings.zoomPan.panEnabled else {return}
        
        func finalPanDelta(deltaX: CGFloat, deltaY: CGFloat) -> (deltaX: CGFloat, deltaY: CGFloat) {
            switch chartSettings.zoomPan.gestureMode {
            case .onlyX: return (deltaX, 0)
            case .onlyY: return (0, deltaY)
            case .max:
                if isPanningX == nil {
                    isPanningX = abs(deltaX) > abs(deltaY)
                }
                return isPanningX! ? (deltaX, 0) : (0, deltaY)
            case .both: return (deltaX, deltaY)
            }
        }
        
        switch sender.state {
            
        case .began:
            lastPanTranslation = nil
            isPanningX = nil
            
            chart?.onPanStart(location: sender.location(in: self))
            
        case .changed:
            
            let trans = sender.translation(in: self)
            
            let location = sender.location(in: self)
            
            let deltaX = lastPanTranslation.map{trans.x - $0.x} ?? trans.x
            let deltaY = lastPanTranslation.map{trans.y - $0.y} ?? trans.y
            
            let (finalDeltaX, finalDeltaY) = finalPanDelta(deltaX: deltaX, deltaY: deltaY)
            
            lastPanTranslation = trans
            
            if (chart?.allowPan(location: location, deltaX: finalDeltaX, deltaY: finalDeltaY, isGesture: true, isDeceleration: false)) ?? false {
                chart?.pan(deltaX: finalDeltaX, deltaY: finalDeltaY, isGesture: true, isDeceleration: false)
            }

        case .ended:
            
            guard let view = sender.view else {print("Recogniser has no view"); return}
            
            
            let velocityX = sender.velocity(in: sender.view).x
            let velocityY = sender.velocity(in: sender.view).y
            
            let (finalDeltaX, finalDeltaY) = finalPanDelta(deltaX: velocityX, deltaY: velocityY)

            let location = sender.location(in: self)
            
            func next(_ index: Int, velocityX: CGFloat, velocityY: CGFloat) {
                DispatchQueue.main.async {
                    
                    self.chart?.pan(deltaX: velocityX, deltaY: velocityY, isGesture: true, isDeceleration: true)
                    
                    if abs(velocityX) > 0.1 || abs(velocityY) > 0.1 {
                        let friction: CGFloat = 0.9
                        next(index + 1, velocityX: velocityX * friction, velocityY: velocityY * friction)
                    }
                }
            }
            let initFriction: CGFloat = 50
            
            
            if (chart?.allowPan(location: location, deltaX: finalDeltaX, deltaY: finalDeltaY, isGesture: true, isDeceleration: false)) ?? false {
                next(0, velocityX: finalDeltaX / initFriction, velocityY: finalDeltaY / initFriction)
            }
            
            chart?.onPanEnd()
            
        case .cancelled: break;
        case .failed: break;
        case .possible: break;
        }
    }
    
    @objc func onTap(_ sender: UITapGestureRecognizer) {
        chart?.onTap(sender.location(in: self))
    }
}
