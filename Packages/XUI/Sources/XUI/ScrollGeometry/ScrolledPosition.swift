import Foundation
import SwiftUI
@frozen
public indirect enum ScrollPositionValue: Hashable {
	case y(CGFloat)
	case id(String?, anchor: UnitPoint)
	case edge(Edge)
	case nearBottom(CGFloat)
}
@frozen
public struct ScrollPositionItem: Hashable {
	public let position: ScrollPositionValue
	public let properties: Properties

	public enum Properties: Hashable, Equatable {
		case animated(Animation = .interpolatingSpring(
			duration: 0.6,
			bounce: 0.0,
			initialVelocity: 0.95,
		))
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

	public static func id(_ value: String?, anchor: UnitPoint = .bottom, properties: Properties = .notAnimated) -> Self {
		.init(.id(value, anchor: anchor), properties: properties)
	}
	public static func edge(_ value: Edge, properties: Properties = .notAnimated) -> Self {
		.init(.edge(value), properties: properties)
	}
	public static func nearBottom(_ space: CGFloat) -> Self {
		.init(.nearBottom(space), properties: .scroll)
	}
}
@frozen
public enum ScrolledPosition: Sendable, Hashable {
	case none
	case atBottom
	case atTop
}
