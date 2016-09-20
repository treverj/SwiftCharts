//
//  ChartViewAnimators.swift
//  SwiftCharts
//
//  Created by ischuetz on 02/09/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

/// Runs a series of animations on a view
open class ChartViewAnimators {
    
    open var animDelay: Float = 0
    open var animDuration: Float = 0.3
    open var animDamping: CGFloat = 0.4
    open var animInitSpringVelocity: CGFloat = 0.5
    
    fileprivate let animators: [ChartViewAnimator]
    
    fileprivate let onFinishAnimations: (() -> Void)?
    fileprivate let onFinishInverts: (() -> Void)?
    
    fileprivate let view: UIView
    
    public init(view: UIView, animators: ChartViewAnimator..., onFinishAnimations: (() -> Void)? = nil, onFinishInverts: (() -> Void)? = nil) {
        self.view = view
        self.animators = animators
        self.onFinishAnimations = onFinishAnimations
        self.onFinishInverts = onFinishInverts
    }
    
    open func animate() {
        for animator in animators {
            animator.prepare(view)
        }
        
        animate({
            for animator in self.animators {
                animator.animate(self.view)
            }
        }, onFinish: {
            self.onFinishAnimations?()
        })
    }
    
    open func invert() {
        animate({
            for animator in self.animators {
                animator.invert(self.view)
            }
            }, onFinish: {
                self.onFinishInverts?()
        })
    }
    
    fileprivate func animate(_ animations: @escaping () -> Void, onFinish: @escaping () -> Void) {
        UIView.animate(withDuration: TimeInterval(animDuration), delay: TimeInterval(animDelay), usingSpringWithDamping: animDamping, initialSpringVelocity: animInitSpringVelocity, options: UIViewAnimationOptions(), animations: {
            animations()
            }, completion: {finished in
                if finished {
                    onFinish()
                }
        })
    }
}

