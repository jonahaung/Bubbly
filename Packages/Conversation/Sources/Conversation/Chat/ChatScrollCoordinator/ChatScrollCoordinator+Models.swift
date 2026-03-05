//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import SwiftUI
import XUI

extension ChatScrollCoordinator {

    struct State: Sendable, Hashable {
        var updateState: ScrollViewUpdate
        var geometry: VScrollGeometry
        var direction: VerticalDirection
        var phase: ScrollPhase
        var isFirstResponder: Bool
        var visibleIDs: [String]
    }

    enum Intent {
        case onVisibilityChange(visibility: Visibility)
        case onScrollGeometryChange(_ oldValue: VScrollGeometry, _ newValue: VScrollGeometry)
        case onScrollPhaseChange(
            _ oldValue: ScrollPhase,
            _ newPhase: ScrollPhase,
            context: ScrollPhaseChangeContext
        )
        case onScrollTargetVisibilityChange(_ newValue: [String])
        case onBottomBarFrameChage(_ oldValue: CGRect, _ newValue: CGRect)
        case onScrollTargetChange(_ y: CGFloat)
        case scrollTo(_ ite: ScrollPositionItem, enqueue: Bool)
    }

    enum DataUpdate: Sendable, Hashable {
        case insert(edge: VerticalEdge)
        case remove(edge: VerticalEdge)
        case reset
        case append(id: String)
    }

    enum ScrollViewUpdate: Hashable {
        case initial, notUpdating, resetting
        case insertingItems(_ edge: VerticalEdge)
        case removingItems(_ edge: VerticalEdge)
        case appendingItem(_ id: String)

        var hasViewLoaded: Bool {
            self != .initial
        }

        var isUpdating: Bool {
            self != .notUpdating
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
            self = .notUpdating
        }
    }
}
