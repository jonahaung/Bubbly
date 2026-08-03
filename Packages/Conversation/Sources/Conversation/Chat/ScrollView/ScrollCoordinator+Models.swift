//  ScrollCoordinator+Models.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import SwiftUI
import XUI

enum ScrollDirection: Sendable, Hashable {
    case up
    case down
    case none
}

extension ScrollCoordinator {

    struct State: Sendable, Hashable {
        var isFirstResponder = false
        var updateState: ScrollViewUpdate = .initial
        var phase: ScrollPhase = .tracking
        var geometry: VScrollGeometry = .empty
    }

    enum Intent {
        case onScrollGeometryChange(
            _ oldValue: VScrollGeometry,
            _ newValue: VScrollGeometry
        )
        case onScrollPhaseChange(
            _ oldValue: ScrollPhase,
            _ newPhase: ScrollPhase,
            context: ScrollPhaseChangeContext
        )
        case begin(_ update: DataUpdate)
    }

    enum DataUpdate: Sendable, Hashable {
        case insert(edge: VerticalEdge)
        case remove(edge: VerticalEdge)
        case append(msg: Message)
        case focus(msg: Message)
    }

    enum ScrollViewUpdate: Sendable, Hashable {
        case initial
        case didEndUpdates
        case willBeginUpdates
        case willEndUpdates
        case dataUpdate(DataUpdate)

        var hasViewLoaded: Bool { self != .initial }
        var isUpdating: Bool { self != .didEndUpdates }
        var isNotUpdating: Bool { !isUpdating }
        var shouldEndUpdates: Bool { self == .willEndUpdates }

        mutating func update(to newValue: Self) {
            guard self != newValue else { return }
            self = newValue
        }
    }
}
