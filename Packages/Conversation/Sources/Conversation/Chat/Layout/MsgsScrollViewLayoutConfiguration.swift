//  MsgsScrollViewLayoutConfiguration.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI
import Database

struct MsgsScrollViewLayoutConfiguration {

    let spacing: CGFloat
    let contentInsets: EdgeInsets
    let screenSize: CGSize
    var boundsWidth: CGFloat {
        screenSize.width
    }

    var bubbleWidthRatio: CGFloat {
        screenSize.height > screenSize.width ? 0.91 : 0.7
    }
}
