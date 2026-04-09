// © 2026 Aung Ko Min

import Database
import SwiftUI
import XUI

extension ScrollCoordinator {
    enum ScrollDirection: Sendable, Hashable {
        case up
        case down
        case none
    }

    struct State: Hashable {
        var updateState: ScrollViewUpdate
        var geometry: VScrollGeometry
        var phase: ScrollPhase
        var isFirstResponder: Bool
        var scrolledPosition: ScrolledPosition
    }

    enum Intent {
        case onScrollGeometryChange(_ oldValue: VScrollGeometry, _ newValue: VScrollGeometry)
        case onScrollPhaseChange(
            _ oldValue: ScrollPhase,
            _ newPhase: ScrollPhase,
            context: ScrollPhaseChangeContext,
        )
        case onBottomBarFrameChage(_ oldValue: CGRect, _ newValue: CGRect)
    }

    enum DataUpdate: Sendable, Hashable {
        case insert(edge: VerticalEdge)
        case remove(edge: VerticalEdge)
        case append(id: String)
    }

    enum ScrollViewUpdate: Hashable {
        case initial
        case didEndUpdates
        case resetting
        case willBeginUpdates
        case insertingItems(_ edge: VerticalEdge)
        case removingItems(_ edge: VerticalEdge)
        case appendingItem(_ id: String)

        // MARK: Internal

        var hasViewLoaded: Bool {
            self != .initial
        }

        var isUpdating: Bool {
            self != .didEndUpdates
        }

        var isNotUpdating: Bool {
            !isUpdating
        }

        mutating func update(to newValue: Self) {
            guard self != newValue else {
                return
            }

            self = newValue
        }

        mutating func setHasViewLoaded() {
            guard self == .initial else {
                return
            }

            self = .didEndUpdates
        }
    }
}
