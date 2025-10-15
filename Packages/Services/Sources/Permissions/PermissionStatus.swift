//
//  PermissionStatus.swift
//  Services
//
//  Created by Aung Ko Min on 18/8/25.
//

import Foundation

public enum PermissionStatus: Int, CustomStringConvertible {
	case authorized
	case denied
	case notDetermined
	case notSupported

	public var description: String {
		switch self {
		case .authorized: return "authorized"
		case .denied: return "denied"
		case .notDetermined: return "not determined"
		case .notSupported: return "not supported"
		}
	}
}
