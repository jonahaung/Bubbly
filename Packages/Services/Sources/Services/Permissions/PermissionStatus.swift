//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public enum PermissionStatus: Int, CustomStringConvertible {
    case authorized
    case denied
    case notDetermined
    case notSupported

    public var description: String {
        switch self {
        case .authorized: "authorized"
        case .denied: "denied"
        case .notDetermined: "not determined"
        case .notSupported: "not supported"
        }
    }
}
