import Foundation
import SwiftUI

public enum ScrollPhase: Hashable, Sendable {
    case idle
    case interacting
    case decelerating
}

public struct ScrollPhaseChangeContext: Hashable, Sendable {
    public init() {}
}

public struct ScrollPositionItem: Hashable, Sendable {
    public enum Properties: Hashable, Sendable {
        case scroll
        case animated(AnimationDescriptor)
    }

    public enum AnimationDescriptor: Hashable, Sendable {
        case easeOut(duration: Double)
    }

    public let y: CGFloat
    public let properties: Properties

    private init(y: CGFloat, properties: Properties) {
        self.y = y
        self.properties = properties
    }

    public static func y(_ y: CGFloat, properties: Properties) -> Self {
        Self(y: y, properties: properties)
    }
}

public enum ScrolledPosition: Sendable, Hashable {
    case atTop
    case atBottom
    case none
}

@frozen
public struct VScrollGeometry: Hashable, Sendable {
    public let contentHeight: CGFloat
    public let boundsHeight: CGFloat
    public var offsetY: CGFloat
    public let topInset: CGFloat
    public let bottomInset: CGFloat

    public init(
        contentHeight: CGFloat,
        boundsHeight: CGFloat,
        offsetY: CGFloat,
        topInset: CGFloat,
        bottomInset: CGFloat
    ) {
        self.contentHeight = contentHeight
        self.boundsHeight = boundsHeight
        self.offsetY = offsetY
        self.topInset = topInset
        self.bottomInset = bottomInset
    }

    public static let empty = VScrollGeometry(
        contentHeight: .zero,
        boundsHeight: .zero,
        offsetY: .zero,
        topInset: .zero,
        bottomInset: .zero
    )

    public var bottomMostOffset: CGFloat {
        contentHeight - boundsHeight + topInset
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
}

public enum ScrollCoordinator {
    public enum ScrollDirection: Sendable, Hashable {
        case up
        case down
        case none
    }

    public struct State: Hashable, Sendable {
        public var updateState: ScrollViewUpdate
        public var geometry: VScrollGeometry
        public var phase: ScrollPhase
        public var isFirstResponder: Bool
        public var scrolledPosition: ScrolledPosition

        public init(
            updateState: ScrollViewUpdate,
            geometry: VScrollGeometry,
            phase: ScrollPhase,
            isFirstResponder: Bool,
            scrolledPosition: ScrolledPosition
        ) {
            self.updateState = updateState
            self.geometry = geometry
            self.phase = phase
            self.isFirstResponder = isFirstResponder
            self.scrolledPosition = scrolledPosition
        }
    }

    public enum Intent: Sendable, Hashable {
        case onScrollGeometryChange(VScrollGeometry, VScrollGeometry)
        case onScrollPhaseChange(ScrollPhase, ScrollPhase, context: ScrollPhaseChangeContext)
        case onBottomBarFrameChage(CGRect, CGRect)
    }

    public enum DataUpdate: Sendable, Hashable {
        case insert(edge: VerticalEdge)
        case remove(edge: VerticalEdge)
        case append(id: String)
    }

    public enum ScrollViewUpdate: Hashable, Sendable {
        case initial
        case didEndUpdates
        case resetting
        case willBeginUpdates
        case insertingItems(VerticalEdge)
        case removingItems(VerticalEdge)
        case appendingItem(String)

        public var hasViewLoaded: Bool {
            self != .initial
        }

        public var isUpdating: Bool {
            self != .didEndUpdates
        }

        public var isNotUpdating: Bool {
            !isUpdating
        }

        public mutating func update(to newValue: Self) {
            guard self != newValue else {
                return
            }
            self = newValue
        }

        public mutating func setHasViewLoaded() {
            guard self == .initial else {
                return
            }
            self = .didEndUpdates
        }
    }
}
