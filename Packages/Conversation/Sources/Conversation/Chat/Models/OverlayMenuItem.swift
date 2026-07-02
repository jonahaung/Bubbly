//  OverlayMenuItem.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import Foundation
import Services

struct OverlayMenuItem: Hashable, Sendable, Identifiable {
    let id: String
    var frame: CGRect

    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }

    static func == (lhs: OverlayMenuItem, rhs: OverlayMenuItem) -> Bool {
        lhs.id == rhs.id
    }
}
