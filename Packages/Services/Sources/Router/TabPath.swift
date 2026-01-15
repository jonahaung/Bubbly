//
//  TabPath.swift
//  Services
//
//  Created by Aung Ko Min on 18/8/25.
//

import Database
import Foundation
import XUI

public enum TabPath: Int, Sendable, Hashable, CaseIterable, Identifiable, CaseNameReflectable {
    case inbox
    case contacts
    case test
    case settings

    public var id: Int { rawValue }

    public var systemName: String {
        switch self {
        case .inbox:
            "message"
        case .contacts:
            "at.circle"
        case .test:
            "checkmark.seal.fill"
        case .settings:
            "circle.hexagongrid.fill"
        }
    }
}
