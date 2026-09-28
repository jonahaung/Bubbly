// © 2026 Aung Ko Min

import Database
import Foundation
import XUI

public enum TabPath: Int, Codable, Sendable, CaseIterable, CaseNameReflectable, Identifiable {
    public var id: Int {
        rawValue
    }

    case inbox
    case contacts
    case settings
    case search

    public var systemName: String {
        switch self {
        case .inbox:
            "message"
        case .contacts:
            "book.pages.fill"
        case .settings:
            "person.crop.circle.fill"
        case .search:
            "magnifyingglass"
        }
    }

    public var name: String {
        switch self {
        case .inbox: String(localized: "Inbox", comment: "Tab title")
        case .contacts: String(localized: "Contact", comment: "Tab title")
        case .settings: String(localized: "Settings", comment: "Tab title")
        case .search:
            String(localized: "Search", comment: "Tab title")
        }
    }

    public var customizationID: String {
        "com.example.apple-samplecode.DestinationVideo." + name
    }
}
