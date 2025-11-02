//
//  TabPath.swift
//  Services
//
//  Created by Aung Ko Min on 18/8/25.
//

import Foundation
import Database

public enum TabPath: String, Sendable, Hashable, CaseIterable, Identifiable {
	case inbox
	case contacts
	case test
	case html
	public var id: String { rawValue }
}
