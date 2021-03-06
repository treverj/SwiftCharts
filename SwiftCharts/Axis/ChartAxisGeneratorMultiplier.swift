//
//  ChartAxisGeneratorMultiplier.swift
//  SwiftCharts
//
//  Created by ischuetz on 27/06/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public enum ChartAxisGeneratorMultiplierUpdateMode {
    case Halve
    case Nice
}

public typealias ChartAxisGeneratorMultiplierUpdater = (_ axis: ChartAxis, _ generator: ChartAxisGeneratorMultiplier) -> Double

open class ChartAxisGeneratorMultiplier: ChartAxisValuesGenerator {
    
    public var first: Double? {
        return nil
    }
    
    public var last: Double?  {
        return nil
    }
    
    var multiplier: Double
    
    /// After zooming in a while the multiplier may be rounded down to 0, which means the intervals are not divisible anymore. We store the last multiplier which worked and keep returning values corresponding to it until the user zooms out until a new valid multiplier.
    private var lastValidMultiplier: Double?
    
    private let multiplierUpdater: ChartAxisGeneratorMultiplierUpdater
    
    public init(_ multiplier: Double, multiplierUpdateMode: ChartAxisGeneratorMultiplierUpdateMode = .Halve) {
        
        let multiplierUpdater: ChartAxisGeneratorMultiplierUpdater = {
            switch multiplierUpdateMode {
            case .Halve: return MultiplierUpdaters.halve
            case .Nice: return MultiplierUpdaters.nice
            }
        }()
        
        self.multiplier = multiplier
        self.multiplierUpdater = multiplierUpdater
    }
    
    public func axisInitialized(_ axis: ChartAxis) {}
    
    public func generate(_ axis: ChartAxis) -> [Double] {

        let updatedMultiplier = multiplierUpdater(axis, self)
        
        return generate(axis: axis, multiplier: updatedMultiplier)
    }
    
    private func generate(axis: ChartAxis, multiplier: Double) -> [Double] {
        
        let modelStart = calculateModelStart(axis: axis, multiplier: multiplier)
        
        var values = [Double]()
        var scalar = modelStart
        while scalar <= axis.lastVisible {
            if ((scalar =~ axis.firstInit && axis.zoomFactor =~ 1) || scalar >= axis.firstVisible) && ((scalar =~ axis.lastInit && axis.zoomFactor =~ 1) || scalar <= axis.lastVisible) {
                values.append(scalar)
            }
            let newScalar = incrementScalar(scalar: scalar, multiplier: multiplier)
            
            if newScalar =~ scalar {
                return lastValidMultiplier.map{lastMultiplier in
                    generate(axis: axis, multiplier: lastMultiplier).filter{$0 >= axis.firstVisible && $0 <= axis.lastVisible}
                } ?? []
                
            } else {
                lastValidMultiplier = multiplier
            }
            
            scalar = newScalar
        }
        
        return values
    }
    
    func calculateModelStart(axis: ChartAxis, multiplier: Double) -> Double {
        return (floor((axis.firstVisible - axis.firstInit) / multiplier) * multiplier) + (axis.firstInit)
    }
    
    func incrementScalar(scalar: Double, multiplier: Double) -> Double {
        return scalar + multiplier
    }
}

private struct MultiplierUpdaters {
 
    static func halve(axis: ChartAxis, generator: ChartAxisGeneratorMultiplier) -> Double {
        // Update intervals when zooming duplicates / halves
        // In order to do this, we round the zooming factor to the lowest value in 2^0, 2^1...2^n sequence (this corresponds to 1x, 2x...nx zooming) and divide the original multiplier by this
        // For example, given a 2 multiplier, when zooming in, zooming factors in 2x..<4x are rounded down to 2x, and dividing our multiplier by 2x, we get a 1 multiplier, meaning during zoom  2x..<4x the values have 1 interval length. If continue zooming in, for 4x..<8x, we get a 0.5 multiplier, etc.
        let roundDecimals: Double = 1000000000000
        return generator.multiplier / pow(2, floor(round(log2(axis.zoomFactor) * roundDecimals) / roundDecimals))
    }

    static func nice(axis: ChartAxis, generator: ChartAxisGeneratorMultiplier) -> Double {
        let origDividers = axis.length / generator.multiplier
        let newDividers = floor(origDividers * axis.zoomFactor)
        return ChartNiceNumberCalculator.niceNumber(axis.length / (Double(newDividers)), round: true)
    }
}
