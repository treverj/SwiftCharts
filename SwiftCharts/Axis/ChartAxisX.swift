//
//  ChartAxisX.swift
//  SwiftCharts
//
//  Created by ischuetz on 26/06/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

public class ChartAxisX: ChartAxis {
    
    public override var length: Double {
        return last - first
    }
    
    public override var screenLength: CGFloat {
        return lastScreen - firstScreen
    }
    
    public override var visibleLength: Double {
        return lastVisible - firstVisible
    }
    
    public override var visibleScreenLength: CGFloat {
        return lastVisibleScreen - firstVisibleScreen
    }
    
    public override func screenLocForScalar(scalar: Double) -> CGFloat {
        return firstScreen + internalScreenLocForScalar(scalar)
    }
    
    public override func innerScreenLocForScalar(scalar: Double) -> CGFloat {
        return internalScreenLocForScalar(scalar)
    }
    
    public override func scalarForScreenLoc(screenLoc: CGFloat) -> Double {
        return Double((screenLoc - firstScreen) * modelToScreenRatio) + first
    }
    
    public override func innerScalarForScreenLoc(screenLoc: CGFloat) -> Double {
        return Double(screenLoc * modelToScreenRatio) + first
    }
    
    public override var firstModelValueInBounds: Double {
        return firstVisible + screenToModelLength(paddingFirstScreen)
    }
    
    public override var lastModelValueInBounds: Double {
        return lastVisible - screenToModelLength(paddingLastScreen)
    }

    override func onTransformUpdate(transform: ChartTransform) {
        firstScreen = transform.applyX(firstScreenInit)
        lastScreen = transform.applyX(lastScreenInit)
    }
    
    override func zoom(scaleX: CGFloat, scaleY: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        zoom(scaleX / CGFloat(zoomFactor), y: scaleY, centerX: centerX, centerY: centerY)
    }
    
    public override init(first: Double, last: Double, firstScreen: CGFloat, lastScreen: CGFloat, paddingFirstScreen: CGFloat = 0, paddingLastScreen: CGFloat = 0) {
        super.init(first: first, last: last, firstScreen: firstScreen, lastScreen: lastScreen, paddingFirstScreen: paddingFirstScreen, paddingLastScreen: paddingLastScreen)
        self.first = firstInit - screenToModelLength(paddingFirstScreen)
        self.last = lastInit + screenToModelLength(paddingLastScreen)
    }
}
