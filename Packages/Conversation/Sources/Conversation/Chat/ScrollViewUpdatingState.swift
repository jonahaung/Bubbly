//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

enum ScrollViewUpdatingState: Hashable {
    case initial, notUpdating, resetting
    case insertingItems(_ edge: VerticalEdge)
    case removingItems(_ edge: VerticalEdge)
    case appendingItem(_ id: String)
}

extension ScrollViewUpdatingState {
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
