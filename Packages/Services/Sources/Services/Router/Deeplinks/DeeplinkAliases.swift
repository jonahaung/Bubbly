//
//  DeeplinkAliases.swift
//  Services
//
//  Created by Aung Ko Min on 29/1/26.
//
import Foundation

public struct DeeplinkAliases: Sendable, Equatable {
	public var routeAliases: [String: String] // alias -> canonical

	public init(routeAliases: [String: String] = [:]) {
		self.routeAliases = routeAliases
	}

	public func canonicalRoute(for route: String) -> String {
		routeAliases[route.lowercased()] ?? route.lowercased()
	}
}

/*
 let aliases = DeeplinkAliases(routeAliases: [
 "conv": "conversation",
 "thread": "conversation",
 "me": "profile"
 ])
 */
