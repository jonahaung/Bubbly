// © 2026 Aung Ko Min

//
//  DeeplinkAliases.swift
//  Services
//
//  Created by Aung Ko Min on 29/1/26.
//
import Foundation

public struct DeeplinkAliases: Sendable, Equatable {
    public var routeAliases: [String: Deeplink.RouteKind]

    public init(routeAliases: [String: Deeplink.RouteKind] = [:]) {
        self.routeAliases = routeAliases.reduce(into: [:]) { partialResult, element in
            partialResult[element.key.lowercased()] = element.value
        }
    }

    public func route(forNormalizedName name: String) -> Deeplink.RouteKind? {
        routeAliases[name] ?? .init(name: name)
    }

    public func route(for name: String) -> Deeplink.RouteKind? {
        route(forNormalizedName: name.lowercased())
    }
}
