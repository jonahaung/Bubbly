//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

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
            "at"
        case .test:
            "app.badge"
        case .settings:
            "shield"
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
		return "com.example.apple-samplecode.DestinationVideo." + self.name
	}
}
