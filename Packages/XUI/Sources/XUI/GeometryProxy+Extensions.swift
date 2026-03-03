//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public extension GeometryProxy {
    var globalFrame: CGRect {
        frame(in: .global)
    }
}

public extension GeometryProxy {
    var insetAdjustedSize: CGSize {
        .init(
            width: size.width - (safeAreaInsets.leading + safeAreaInsets.trailing),
            height: size.height - (safeAreaInsets.top + safeAreaInsets.bottom)
        )
    }

    var ignoreSafeAreaSize: CGSize {
        .init(
            width: size.width + (safeAreaInsets.leading + safeAreaInsets.trailing),
            height: size.height + (safeAreaInsets.top + safeAreaInsets.bottom)
        )
    }
}
