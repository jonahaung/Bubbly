//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import XUI

public struct VScrollGeometry: Sendable, Hashable {
    public let contentHeight: CGFloat
    public let boundsHeight: CGFloat
    public var offsetY: CGFloat
    public let topInset: CGFloat
    public let bottomInset: CGFloat
}

extension VScrollGeometry {
    public init(_ geometry: ScrollGeometry) {
        self.init(
            contentHeight: geometry.contentSize.height,
            boundsHeight: geometry.bounds.height,
            offsetY: geometry.contentOffset.y + geometry.contentInsets.top,
            topInset: geometry.contentInsets.top,
            bottomInset: geometry.contentInsets.bottom
        )
    }

    public static let empty = VScrollGeometry(
        contentHeight: .zero,
        boundsHeight: .zero,
        offsetY: .zero,
        topInset: .zero,
        bottomInset: .zero
    )
}

extension VScrollGeometry {
    public var bottomMostOffset: CGFloat {
        contentHeight - boundsHeight
    }

    public var scrolledPosition: ScrolledPosition {
        if offsetY.rounded() == 0 {
            return .atTop
        }
        if (offsetY + boundsHeight).rounded() == contentHeight.rounded() {
            return .atBottom
        }
        return .none
    }

    public func isNear(_ edge: VerticalEdge) -> Bool {
        switch edge {
        case .top:
            offsetY < boundsHeight / 2
        case .bottom:
            offsetY > (bottomMostOffset - (boundsHeight / 2))
        }
    }

    public func canPaginate(at edge: VerticalEdge) -> Bool {
        switch edge {
        case .top:
            offsetY < boundsHeight / 2
        case .bottom:
            offsetY + (boundsHeight + boundsHeight / 8) > contentHeight
        }
    }
}
