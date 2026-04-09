//
// Copyright © 2026 Aung Ko Min. All rights reserved.
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
        case let .unsupportedScheme(s): "Unsupported scheme: \(s ?? "nil")"
        case let .unsupportedHost(h): "Unsupported host: \(h ?? "nil")"
        case let .unsupportedRoute(r): "Unsupported route: \(r)"
        case let .missingRequiredParameter(route, name):
            "Missing required query param '\(name)' for route '\(route)'"
        case let .emptyRequiredParameter(route, name):
            "Empty required query param '\(name)' for route '\(route)'"
        case let .unknownQueryItems(route, unknown):
            "Unknown query items for '\(route)': \(unknown.joined(separator: ","))"
        }
    }
}
