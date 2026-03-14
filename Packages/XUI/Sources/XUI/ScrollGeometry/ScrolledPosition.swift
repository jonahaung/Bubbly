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

public indirect enum ScrollPositionValue: Hashable {
    case y(CGFloat)
    case id(String?)
    case layoutID(String?)
	case edge(VerticalEdge)
}

public struct ScrollPositionItem: Hashable, Equatable {
    public let position: ScrollPositionValue
    public let properties: Properties

	public enum Properties: Hashable, Equatable {
		case animated(Animation)
		case notAnimated
		case scroll
	}

    public init(_ position: ScrollPositionValue, properties: Properties) {
        self.position = position
		self.properties = properties
    }

	public static func y(_ value: CGFloat, properties: Properties = .notAnimated) -> Self {
		.init(.y(value), properties: properties)
    }

    public static func id(_ value: String?, properties: Properties = .notAnimated) -> Self {
		.init(.id(value), properties: properties)
    }
    public static func edge(_ value: VerticalEdge, properties: Properties = .notAnimated) -> Self {
		.init(.edge(value), properties: properties)
    }
}

public enum ScrolledPosition: Sendable, Hashable {
    case none
    case atBottom
    case atTop
}
