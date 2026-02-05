//
//  AppTab.swift
//  Services
//
//  Created by Aung Ko Min on 29/1/26.
//

import Foundation
import Database

public struct TabMapping: Sendable {
	public var tabForLink: @Sendable (Deeplink) -> TabPath?

    public init(tabForLink: @escaping @Sendable (Deeplink) -> TabPath?) {
        self.tabForLink = tabForLink
    }
}

public extension TabMapping {
	static let `default` = TabMapping { link in
		switch link {
		case .home: return .inbox
		case .settings: return .settings
		default:
			return nil
		}
	}
}

public struct NavMapping: Sendable {
	public var navForLink: @Sendable (Deeplink) -> NavPath?
	public init(navForLink: @escaping @Sendable (Deeplink) -> NavPath?) {
		self.navForLink = navForLink
	}
}
public extension NavMapping {
	static let `default` = NavMapping { link in
		switch link {
		case .conversation(let id):
			return nil
		default:
			return nil
		}
	}
}
