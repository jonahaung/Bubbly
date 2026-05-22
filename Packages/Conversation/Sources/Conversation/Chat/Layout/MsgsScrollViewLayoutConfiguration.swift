//  MsgsScrollViewLayoutConfiguration.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import SwiftUI

struct MsgsScrollViewLayoutConfiguration {
    let spacing: CGFloat
    let contentInsets: EdgeInsets
    let screenBounds: CGRect
    var screenSize: CGSize { screenBounds.size }
    var boundsWidth: CGFloat {
        screenSize.width
    }
    var bubbleWidthRatio: CGFloat {
        screenSize.height > screenSize.width ? 0.91 : 0.7
    }
}
