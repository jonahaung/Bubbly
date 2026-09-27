//  MsgsScrollViewLayoutConfiguration.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import SwiftUI

struct MsgsScrollViewLayoutConfiguration {
    let spacing: CGFloat
    let contentInsets: EdgeInsets
    var screenSize: CGSize

    var boundsWidth: CGFloat {
        screenSize.width
    }
    var bubbleWidthRatio: CGFloat {
        screenSize.height > screenSize.width ? 0.91 : 0.7
    }
}
