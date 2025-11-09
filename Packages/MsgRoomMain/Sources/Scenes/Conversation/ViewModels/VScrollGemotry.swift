//
//  VScrollGemotry.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 8/11/25.
//

import SwiftUI
import XUI

public struct VScrollGeometry: Sendable, Hashable, Equatable {
    public let contentHeight: CGFloat
    public let boundsHeight: CGFloat
    public var offsetY: CGFloat
    public let topInset: CGFloat
    public let bottomInset: CGFloat
    public var visibleRect: CGRect {
        CGRect(
            x: 0,
            y: offsetY + topInset,
            width: 0,
            height: boundsHeight - topInset - bottomInset
        )
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.contentHeight == rhs.contentHeight &&
            lhs.offsetY == rhs.offsetY
    }
}

public extension VScrollGeometry {
    init(_ geometry: ScrollGeometry) {
        self.init(
            contentHeight: geometry.contentSize.height.rounded(toPlaces: 2),
            boundsHeight: geometry.bounds.height,
            offsetY: geometry.contentOffset.y.rounded(toPlaces: 2),
            topInset: geometry.contentInsets.top,
            bottomInset: geometry.contentInsets.bottom
        )
    }

    static let empty = VScrollGeometry(
        contentHeight: .zero,
        boundsHeight: .zero,
        offsetY: .zero,
        topInset: .zero,
        bottomInset: .zero
    )
}

public extension VScrollGeometry {
    var bottomMostOffset: CGFloat {
        contentHeight + bottomInset - boundsHeight
    }

    var topSpace: CGFloat {
        visibleRect.minY
    }

    var bottomSpace: CGFloat {
        contentHeight - visibleRect.maxY
    }

    var isScrolledToBottom: Bool {
        abs(offsetY.rounded() - bottomMostOffset.rounded()) < 1
    }

    var location: ScrollLocation {
        let edge: VerticalEdge = centerFraction < 0.45 ? .top : .bottom
        switch edge {
        case .top:
            return .init(edge: edge, fraction: visibleRect.minY / contentHeight)
        case .bottom:
            return .init(edge: edge, fraction: 1 - (visibleRect.maxY / contentHeight))
        }
    }

    var centerFraction: CGFloat {
        visibleRect.midY / contentHeight
    }

    var scrolledPosition: ScrolledPosition {
        .init(self)
    }
}

public extension VScrollGeometry {
    func targetOffsetY(for rect: CGRect) -> CGFloat {
        let targetY = rect.maxY + bottomInset - boundsHeight
        let minOffsetY = topInset
        let maxOffsetY = bottomMostOffset
        return min(max(targetY, minOffsetY), maxOffsetY)
    }

    func adjustedOffsetY(from oldValue: VScrollGeometry) -> CGFloat {
        guard contentHeight > 0 else { return topInset }
        let diff = contentHeight - oldValue.contentHeight
        guard diff != 0 else {
            return visibleRect.minY
        }
        return oldValue.visibleRect.minY + diff + topInset
    }
}

public extension ScrolledPosition {
    init(_ geometry: VScrollGeometry) {
        if geometry.contentHeight <= geometry.boundsHeight {
            self = .atBottom
            return
        }

        let location = geometry.location
        switch location.edge {
        case .top:
            self = location.fraction <= 0 ? .atTop : .position(location)
        case .bottom:
            self = location.fraction <= 0 ? .atBottom : .position(location)
        }
    }
}
