//
//  ChartPointViewBarGreyOut.swift
//  Examples
//
//  Created by ischuetz on 15/05/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

open class ChartPointViewBarGreyOut: ChartPointViewBar {

    fileprivate let greyOut: Bool
    fileprivate let greyOutDelay: Float
    fileprivate let greyOutAnimDuration: Float
    
    init(p1: CGPoint, p2: CGPoint, width: CGFloat, color: UIColor, animDuration: Float = 0.5, greyOut: Bool = false, greyOutDelay: Float = 1, greyOutAnimDuration: Float = 0.5, selectionViewUpdater: ChartViewSelector? = nil) {
        
        self.greyOut = greyOut
        self.greyOutDelay = greyOutDelay
        self.greyOutAnimDuration = greyOutAnimDuration
        
        super.init(p1: p1, p2: p2, width: width, bgColor: color, animDuration: animDuration, selectionViewUpdater: selectionViewUpdater)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public required convenience init(p1: CGPoint, p2: CGPoint, width: CGFloat, bgColor: UIColor?, animDuration: Float, selectionViewUpdater: ChartViewSelector? = nil) {
        self.init(p1: p1, p2: p2, width: width, color: bgColor ?? UIColor.black, animDuration: animDuration, selectionViewUpdater: selectionViewUpdater)
    }

    override open func didMoveToSuperview() {
        
        super.didMoveToSuperview()
        
        if self.greyOut {
            UIView.animate(withDuration: CFTimeInterval(self.greyOutAnimDuration), delay: CFTimeInterval(self.greyOutDelay), options: UIViewAnimationOptions.curveEaseOut, animations: {() -> Void in
                self.backgroundColor = UIColor.gray
            }, completion: nil)
        }
    }
}
