//
//  ChartPointViewBarStacked.swift
//  Examples
//
//  Created by ischuetz on 15/05/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

public struct TappedChartPointViewBarStacked {
    public let barView: ChartPointViewBarStacked
    public let stackFrame: (index: Int, view: UIView, viewFrameRelativeToBarSuperview: CGRect)
}


private class ChartBarStackFrameView: UIView {
    
    var isSelected: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public typealias ChartPointViewBarStackedFrame = (rect: CGRect, color: UIColor)

open class ChartPointViewBarStacked: ChartPointViewBar {
    
    fileprivate var stackViews: [(index: Int, view: ChartBarStackFrameView, targetFrame: CGRect)] = []
    
    var stackFrameSelectionViewUpdater: ChartViewSelector?
    
    var stackedTapHandler: ((TappedChartPointViewBarStacked) -> Void)? {
        didSet {
            if stackedTapHandler != nil && gestureRecognizers?.isEmpty ?? true {
                enableTap()
            }
        }
    }
    
    public required init(p1: CGPoint, p2: CGPoint, width: CGFloat, stackFrames: [ChartPointViewBarStackedFrame], animDuration: Float = 0.5, stackFrameSelectionViewUpdater: ChartViewSelector? = nil, selectionViewUpdater: ChartViewSelector? = nil) {
        self.stackFrameSelectionViewUpdater = stackFrameSelectionViewUpdater
        
        super.init(p1: p1, p2: p2, width: width, bgColor: UIColor.clear, animDuration: animDuration, selectionViewUpdater: selectionViewUpdater)
        
        for (index, stackFrame) in stackFrames.enumerated() {
            let (targetFrame, firstFrame): (CGRect, CGRect) = {
                if (p1.y - p2.y) =~ 0 { // horizontal
                    let initFrame = CGRect(x: 0, y: stackFrame.rect.origin.y, width: 0, height: stackFrame.rect.size.height)
                    return (stackFrame.rect, initFrame)
                    
                } else { // vertical
                    let initFrame = CGRect(x: stackFrame.rect.origin.x, y: self.frame.height, width: stackFrame.rect.size.width, height: 0)
                    return (stackFrame.rect, initFrame)
                }
            }()
            
            let v = ChartBarStackFrameView(frame: firstFrame)
            v.backgroundColor = stackFrame.color
            
            stackViews.append((index, v, targetFrame))
            
            addSubview(v)
        }
    }
    
    override func onTap(sender: UITapGestureRecognizer) {
        let loc = sender.location(in: self)
        guard let tappedStackFrame = (stackViews.filter{$0.view.frame.contains(loc)}.first) else {
            print("Warn: no stacked frame found in stacked bar")
            return
        }
        
        toggleSelection()
        tappedStackFrame.view.isSelected = !tappedStackFrame.view.isSelected
        
        let f = tappedStackFrame.view.frame.offsetBy(dx: frame.origin.x, dy: frame.origin.y)
        
        stackFrameSelectionViewUpdater?.displaySelected(tappedStackFrame.view, selected: tappedStackFrame.view.isSelected)
        stackedTapHandler?(TappedChartPointViewBarStacked(barView: self, stackFrame: (tappedStackFrame.index, tappedStackFrame.view, f)))
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required init(p1: CGPoint, p2: CGPoint, width: CGFloat, bgColor: UIColor?, animDuration: Float, selectionViewUpdater: ChartViewSelector? = nil) {
        fatalError("init(p1:p2:width:bgColor:animDuration:selectionViewUpdater:) has not been implemented")
    }
    
    override open func didMoveToSuperview() {
        
        func targetState() {
            frame = targetFrame
            for stackFrame in stackViews {
                stackFrame.view.frame = stackFrame.targetFrame
            }
            layoutIfNeeded()
        }
        
        if animDuration =~ 0 {
            targetState()
        } else {
            UIView.animate(withDuration: CFTimeInterval(animDuration), delay: 0, options: .curveEaseOut, animations: {
                targetState()
            }, completion: nil)
        }

    }
}
