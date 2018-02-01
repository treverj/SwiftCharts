//
//  ChartAxisValue.swift
//  SwiftCharts
//
//  Created by ischuetz on 26/07/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

extension Array where Element: ChartAxisValue {

    func calculateLabelsDimensions() -> (total: CGSize, max: CGSize) {
        return flatMap({
            guard let label = $0.labels.first else {return nil}
            return label.text.size(label.settings.font)
        }).reduce((total: CGSize.zero, max: CGSize.zero), {(lhs: (total: CGSize, max: CGSize), rhs: CGSize) in
            let width = (lhs.total.width + CGFloat(rhs.width))
            let otherWidth = lhs.max.width > rhs.width ? lhs.max.width : rhs.width
            let height = lhs.max.height > rhs.height ? lhs.max.height : rhs.height
            return (total:
                CGSize(width: width, height: lhs.total.height + rhs.height),
                    max:
                CGSize(width: otherWidth, height: height)
            )
        })
    }
}
