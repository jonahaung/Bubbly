import Foundation
import SwiftUI
@frozen
public indirect enum ScrollPositionValue: Hashable {
	case y(CGFloat)
	case id(String?)
	case edge(VerticalEdge)
	case snap(y: CGFloat, edge: VerticalEdge)
	case snapToBottom
}
@frozen
public struct ScrollPositionItem: Hashable {
	public let position: ScrollPositionValue
	public let properties: Properties

	public enum Properties: Hashable, Equatable {
		case animated(Animation)
		case notAnimated
		case scroll
		case none
	}

	public init(_ position: ScrollPositionValue, properties: Properties) {
		self.position = position
		self.properties = properties
	}

	public static func y(_ value: CGFloat, properties: Properties = .notAnimated) -> Self {
		.init(.y(value), properties: properties)
	}

	public static func id(_ value: String?, properties: Properties = .notAnimated) -> Self {
		.init(.id(value), properties: properties)
	}
	public static func edge(_ value: VerticalEdge, properties: Properties = .notAnimated) -> Self {
		.init(.edge(value), properties: properties)
	}
	public static func snapToBottom() -> Self {
		.init(.snapToBottom, properties: .none)
	}
	public static func snap(_ y: CGFloat, edge: VerticalEdge) -> Self {
		.init(.snap(y: y, edge: edge), properties: .none)
	}
}
@frozen
public enum ScrolledPosition: Sendable, Hashable {
	case none
	case atBottom
	case atTop
}
