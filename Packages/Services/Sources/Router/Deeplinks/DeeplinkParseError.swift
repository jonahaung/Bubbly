//
//  DeeplinkParseError.swift
//  Services
//
//  Created by Aung Ko Min on 29/1/26.
//

import Foundation

public enum DeeplinkParseError: Error, Sendable, Equatable, CustomStringConvertible {
	case unsupportedScheme(String?)
	case unsupportedHost(String?)
	case unsupportedRoute(String)
	case missingRequiredParameter(route: String, name: String)
	case emptyRequiredParameter(route: String, name: String)
	case unknownQueryItems(route: String, unknown: [String])

	public var description: String {
		switch self {
		case .unsupportedScheme(let s): return "Unsupported scheme: \(s ?? "nil")"
		case .unsupportedHost(let h): return "Unsupported host: \(h ?? "nil")"
		case .unsupportedRoute(let r): return "Unsupported route: \(r)"
		case .missingRequiredParameter(let route, let name):
			return "Missing required query param '\(name)' for route '\(route)'"
		case .emptyRequiredParameter(let route, let name):
			return "Empty required query param '\(name)' for route '\(route)'"
		case .unknownQueryItems(let route, let unknown):
			return "Unknown query items for '\(route)': \(unknown.joined(separator: ","))"
		}
	}
}
