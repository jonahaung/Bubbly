//  ScrollCoordinator+Models.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database

extension ScrollCoordinator {
    
    struct PaginationState: Hashable {
        var canLoadOlder: Bool
        var canLoadNewer: Bool
        var canAdjustSize: Bool
        init(
            canLoadOlder: Bool = false,
            canLoadNewer: Bool = false,
            canAdjustSize: Bool = false
        ) {
            self.canLoadOlder = canLoadOlder
            self.canLoadNewer = canLoadNewer
            self.canAdjustSize = canAdjustSize
        }
    }

    enum ScrollDirection: Hashable {
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
        var scrollDirection: ScrollDirection = .none
    }

    enum Intent {
        case onScrollGeometryChange(
            _ oldValue: VScrollGeometry, _ newValue: VScrollGeometry
        )
        case onScrollPhaseChange(
            _ oldValue: ScrollPhase, _ newPhase: ScrollPhase,
            context: ScrollPhaseChangeContext
        )
        case begin(_ update: DataUpdate)
    }

    enum DataUpdate: Hashable {
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
        
        var hasViewLoaded: Bool { self != .initial }
        var isUpdating: Bool { self != .didEndUpdates }
        var isNotUpdating: Bool { !isUpdating }
        var canReduceUpdates: Bool {
            isUpdating && self != .didEndUpdates && self != .willEndUpdates
        }
        
        mutating func update(to newValue: Self) {
            guard self != newValue else { return }
            self = newValue
        }
        mutating func setHasViewLoaded() {
            guard self == .initial else { return }
            self = .didEndUpdates
        }
    }
}
