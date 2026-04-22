//  EditMode+Extensions.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

public extension EditMode {
    mutating func toggle() {
        self = switch self {
        case .inactive:
            .active
        case .transient:
            .inactive
        case .active:
            .inactive
        @unknown default:
            .inactive
        }
    }
}
