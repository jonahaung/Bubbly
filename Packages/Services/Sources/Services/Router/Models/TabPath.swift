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
    case test
    case settings

    public var systemName: String {
        switch self {
        case .inbox:
            "message"
        case .contacts:
            "book.pages.fill"
        case .test:
            "apple.logo"
        case .settings:
            "person.crop.circle.fill"
        }
    }

    public var name: String {
        switch self {
        case .inbox: String(localized: "Inbox", comment: "Tab title")
        case .contacts: String(localized: "Contact", comment: "Tab title")
        case .test: String(localized: "Tests", comment: "Tab title")
        case .settings: String(localized: "Settings", comment: "Tab title")
        }
    }

    public var customizationID: String {
        "com.example.apple-samplecode.DestinationVideo." + name
    }
}
