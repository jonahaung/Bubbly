//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct MsgsScrollViewLayoutConfiguration {
	
    let superTopSpace = CGFloat(50)
    let spacing: CGFloat
    let contentInsets: EdgeInsets
    var boundsWidth: CGFloat
    var layoutDirection: VerticalEdge

    init(_ spacing: CGFloat, _ contentInsets: EdgeInsets, direction: VerticalEdge = .bottom) {
        self.spacing = spacing
        self.contentInsets = contentInsets
        boundsWidth = 0
        layoutDirection = direction
    }
}
