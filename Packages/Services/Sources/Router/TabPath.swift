//
//  TabPath.swift
//  Services
//
//  Created by Aung Ko Min on 18/8/25.
//

import Foundation
import Database

public enum TabPath: Sendable, Hashable, CaseIterable, Identifiable {
	public var id: String { rawValue }
	case inbox, contacts, test, html
	public var rawValue: String {
		Mirror(reflecting: self).children.first?.label ?? "\(self)"
	}
}
