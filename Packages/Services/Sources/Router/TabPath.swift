//
//  TabPath.swift
//  Services
//
//  Created by Aung Ko Min on 18/8/25.
//

import Foundation
import Database
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
			return "tray.fill"
		case .contacts:
			return "person.2.fill"
		case .test:
			return "checkmark.seal.fill"
		case .settings:
			return "gearshape.fill"
		}
	}
}
