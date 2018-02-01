//
//  ChartPointViewBar.swift
//  Examples
//
//  Created by ischuetz on 14/05/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

open class ChartPointViewBar: UIView {
    
    let targetFrame: CGRect
    let animDuration: Float
    
    var isSelected: Bool = false
    
    var selectionViewUpdater: ChartViewSelector?
    
    var tapHandler: ((ChartPointViewBar) -> Void)? {
        didSet {
            if tapHandler != nil && gestureRecognizers?.isEmpty ?? true {
                enableTap()
            }
        }
    }
    
    public let isHorizontal: Bool
    
    public required init(p1: CGPoint, p2: CGPoint, width: CGFloat, bgColor: UIColor? = nil, animDuration: Float = 0.5, selectionViewUpdater: ChartViewSelector? = nil) {
        
        let (targetFrame, firstFrame): (CGRect, CGRect) = {
            if (p1.y - p2.y) =~ 0 { // horizontal
                let targetFrame = CGRect(x: p1.x, y: p1.y - width / 2, width: p2.x - p1.x, height: width)
                let initFrame = CGRect(x: targetFrame.origin.x, y: targetFrame.origin.y, width:0, height: targetFrame.size.height)
                return (targetFrame, initFrame)
                
            } else { // vertical
                let targetFrame = CGRect(x: p1.x - width / 2, y: p1.y, width: width, height: p2.y - p1.y)
                let initFrame = CGRect(x: targetFrame.origin.x, y: targetFrame.origin.y, width: targetFrame.size.width, height: 0)
                return (targetFrame, initFrame)
            }
        }()
        
        self.targetFrame =  targetFrame
        self.animDuration = animDuration
        
        self.selectionViewUpdater = selectionViewUpdater
        
        isHorizontal = p1.y == p2.y
        
        super.init(frame: firstFrame)
        
        self.backgroundColor = bgColor
    }

    func enableTap() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.addGestureRecognizer(tapRecognizer)
    }
    
    func onTap(sender: UITapGestureRecognizer) {
        toggleSelection()
        tapHandler?(self)
    }
    
    func toggleSelection() {
        isSelected = !isSelected
        selectionViewUpdater?.displaySelected(self, selected: isSelected)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func didMoveToSuperview() {
        
        func targetState() {
            frame = targetFrame
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
