//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Foundation
import XUI

public enum TabPath: Int, Sendable, CaseIterable, CaseNameReflectable, Identifiable {
    public var id: Int {
        rawValue
    }

    case inbox
    case contacts
    case test
    case settings

    public var systemName: String {
        switch self {
        case .inbox:
            "app.badge"
        case .contacts:
            "at"
        case .test:
            "magnifyingglass"
        case .settings:
            "shield"
        }
    }
}
