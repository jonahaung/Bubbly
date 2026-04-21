// © 2026 Aung Ko Min

import Database
import SwiftUI
import XUI

extension ScrollCoordinator {
    struct PaginationState: Hashable {
        let canLoadOlder: Bool
        let canLoadNewer: Bool
        let canAdjustSize: Bool

        init(
            canLoadOlder: Bool = false,
            canLoadNewer: Bool = false,
            canAdjustSize: Bool = false,
        ) {
            self.canLoadOlder = canLoadOlder
            self.canLoadNewer = canLoadNewer
            self.canAdjustSize = canAdjustSize
        }
    }

    enum ScrollDirection: Sendable, Hashable {
        case up
        case down
        case none
    }

    struct State: Hashable {
        var isFirstResponder = false
        var updateState: ScrollViewUpdate = .initial
        var geometry: VScrollGeometry = .empty
        var phase: ScrollPhase = .idle
        var scrolledPosition: ScrolledPosition = .none
        var paginationState: PaginationState?
    }

    enum Intent {
        case onScrollGeometryChange(
            _ oldValue: VScrollGeometry,
            _ newValue: VScrollGeometry,
        )
        case onScrollPhaseChange(
            _ oldValue: ScrollPhase,
            _ newPhase: ScrollPhase,
            context: ScrollPhaseChangeContext,
        )
    }

    enum DataUpdate: Sendable, Hashable {
        case insert(edge: VerticalEdge, geometry: VScrollGeometry)
        case remove(edge: VerticalEdge, geometry: VScrollGeometry)
        case append(msgID: String)
        case resetting(msg: Message)
    }

    enum ScrollViewUpdate: Hashable {
        case initial
        case didEndUpdates
        case willEndUpdates
        case willBeginUpdates
        case dataUpdate(DataUpdate)

        var hasViewLoaded: Bool {
            self != .initial
        }

        var isUpdating: Bool {
            self != .didEndUpdates
        }

        var canReduceUpdates: Bool {
            isUpdating && self != .didEndUpdates && self != .willEndUpdates
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
