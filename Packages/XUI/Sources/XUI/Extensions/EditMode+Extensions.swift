//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public extension EditMode {
    mutating func toggle() {
        switch self {
        case .inactive:
            self = .active
        case .transient:
            self = .inactive
        case .active:
            self = .inactive
        @unknown default:
            self = .inactive
        }
    }
}
