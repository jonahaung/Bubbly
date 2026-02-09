//
//  DeeplinkRouteDefinition.swift
//  Services
//
//  Created by Aung Ko Min on 29/1/26.
//

import Foundation

public struct DeeplinkRouteDefinition<Link: Sendable>: Sendable {
	public let name: String
	public let requiredQueryItems: [String]
	public let allowedQueryItems: Set<String> // include required here
	public let makeLink: @Sendable (_ query: [String: String]) -> Link?
	public let queryFromLink: @Sendable (_ link: Link) -> [String: String]?

	public init(name: String,
	            requiredQueryItems: [String] = [],
	            allowedQueryItems: Set<String> = [],
	            makeLink: @escaping @Sendable (_ query: [String: String]) -> Link?,
	            queryFromLink: @escaping @Sendable (_ link: Link) -> [String: String]?)
	{
		self.name = name
		self.requiredQueryItems = requiredQueryItems
		self.allowedQueryItems = allowedQueryItems.isEmpty
			? Set(requiredQueryItems) // default: allow only required
			: allowedQueryItems
		self.makeLink = makeLink
		self.queryFromLink = queryFromLink
	}
}
