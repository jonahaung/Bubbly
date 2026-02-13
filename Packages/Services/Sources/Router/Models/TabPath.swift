import Database
import Foundation
import XUI

public enum TabPath: Sendable, Hashable, CaseIterable, CaseNameReflectable {
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
