//
//  ScrolledPosition.swift
//  XUI
//
//  Created by Aung Ko Min on 28/2/25.
//

import Foundation
import SwiftUI

public extension ScrollGeometry {
    static let empty = ScrollGeometry(contentOffset: .zero, contentSize: .zero, contentInsets: .init(), containerSize: .zero)
    var scrolledPosition: ScrolledPosition {
        ScrolledPosition(self)
    }

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
        let offsetY = oldValue.visibleRect.minY + diffHeight + contentInsets.top
        return offsetY
    }
}

public struct ScrollLocation: Hashable {
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

public indirect enum ScrollPositionItem: Hashable {
    case offset(yPosition: CGFloat, animated: Bool = true, duration: Double? = nil)
    case id(value: String, anchor: UnitPoint? = nil, animated: Bool = true, duration: Double? = nil)
    case layoutID(value: String, anchor: UnitPoint? = nil, animated: Bool = true, duration: Double? = nil)
    case bottom(animated: Bool = true, duration: Double? = nil)
}

public enum ScrolledPosition: Hashable {
    case none
    case atBottom
    case atTop
    case position(ScrollLocation)

    public init(_ geometry: ScrollGeometry) {
        if geometry.contentSize.height < geometry.bounds.height {
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

    public var description: String {
        switch self {
        case .none:
            "none"
        case .atBottom:
            "atBottom"
        case .atTop:
            "atTop"
        case let .position(location):
            location.description
        }
    }

    public var nearBottom: Bool {
        switch self {
        case .atBottom:
            true
        case let .position(location):
            switch location.edge {
            case .top:
                false
            case .bottom:
                location.fraction < 0.1
            }
        default:
            false
        }
    }
}
