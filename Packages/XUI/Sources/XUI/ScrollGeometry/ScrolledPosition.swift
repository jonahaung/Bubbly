//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

public extension ScrollGeometry {
    static let empty = ScrollGeometry(
        contentOffset: .zero,
        contentSize: .zero,
        contentInsets: .init(),
        containerSize: .zero
    )
    var location: ScrollLocation {
        let edge = centerLocation < 0.45 ? VerticalEdge.top : .bottom
        switch edge {
        case .top:
            return .init(edge: edge, fraction: visibleRect.minY / contentSize.height)
        case .bottom:
            return .init(edge: edge, fraction: 1 - (visibleRect.maxY / contentSize.height))
        }
    }

    var centerLocation: CGFloat {
        visibleRect.midY / contentSize.height
    }

    func adjustedOffsetY(from oldValue: ScrollGeometry) -> CGFloat {
        guard contentSize.height > 0 else { return contentInsets.top }
        let diffHeight = contentSize.height - oldValue.contentSize.height
        guard diffHeight != 0 else {
            return visibleRect.minY
        }
        return oldValue.visibleRect.minY + diffHeight + contentInsets.top
    }
}

public struct ScrollLocation: Sendable, Hashable {
    public let fraction: CGFloat
    public let edge: VerticalEdge
    public init(edge: VerticalEdge, fraction: CGFloat) {
        self.fraction = fraction
        self.edge = edge
    }

    public var description: String {
        switch edge {
        case .top:
            "Top \(fraction)"
        case .bottom:
            "Bottom \(fraction)"
        }
    }
}

public indirect enum ScrollPositionValue: Hashable, Sendable {
    case y(CGFloat)
    case id(String?)
    case layoutID(String?)
    case edge(Edge)
    case snapToY(CGFloat)
    case snapToBottom
}

public struct ScrollPositionItem: Hashable, Equatable {
    public let position: ScrollPositionValue
    public let animation: Animation?

    public init(_ position: ScrollPositionValue, animation: Animation? = nil) {
        self.position = position
        self.animation = animation
    }

    public static func y(_ value: CGFloat, animation: Animation? = nil) -> Self {
        .init(.y(value), animation: animation)
    }

    public static func id(_ value: String?, animation: Animation? = nil) -> Self {
        .init(.id(value), animation: animation)
    }

    public static func layoutID(_ value: String?, animation: Animation? = nil) -> Self {
        .init(.layoutID(value), animation: animation)
    }

    public static func edge(_ value: Edge, animation: Animation? = nil) -> Self {
        .init(.edge(value), animation: animation)
    }

    public static func snapToBottom() -> Self {
        .init(.snapToBottom, animation: nil)
    }

    public static func snapToY(_ y: CGFloat) -> Self {
        .init(.snapToY(y), animation: nil)
    }
}

public enum ScrolledPosition: Sendable, Hashable {
    case none
    case atBottom
    case atTop

//    public init(_ geometry: ScrollGeometry) {
//        if geometry.contentSize.height < geometry.bounds.height {
//            self = .atBottom
//            return
//        }
//        let location = geometry.location
//        switch location.edge {
//        case .top:
//            self = location.fraction <= 0 ? .atTop : .position(location)
//        case .bottom:
//            self = location.fraction <= 0 ? .atBottom : .position(location)
//        }
//    }

    public var description: String {
        switch self {
        case .none:
            "none"
        case .atBottom:
            "atBottom"
        case .atTop:
            "atTop"
        }
    }

    public var nearBottom: Bool {
        switch self {
        case .atBottom:
            true
        default:
            false
        }
    }
}
