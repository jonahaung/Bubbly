import Foundation
import SwiftUI

@frozen
public struct VScrollGeometry: Hashable {
	public let contentHeight: CGFloat
	public let boundsHeight: CGFloat
	public var offsetY: CGFloat
	public let topInset: CGFloat
	public let bottomInset: CGFloat
}

public extension VScrollGeometry {
	init(_ geometry: ScrollGeometry) {
		self.init(
			contentHeight: geometry.contentSize.height,
			boundsHeight: geometry.bounds.height,
			offsetY: geometry.contentOffset.y + geometry.contentInsets.top,
			topInset: geometry.contentInsets.top,
			bottomInset: geometry.contentInsets.bottom,
		)
	}

	nonisolated
	static let empty: VScrollGeometry = .init(
		contentHeight: .zero,
		boundsHeight: .zero,
		offsetY: .zero,
		topInset: .zero,
		bottomInset: .zero,
	)
}

public extension VScrollGeometry {
	var bottomMostOffset: CGFloat {
		if contentHeight == 0 {
			return 0
		}
		return contentHeight - boundsHeight + topInset
	}

	var scrolledPosition: ScrolledPosition {
		if offsetY == 0 {
			return .atTop
		}
		let diff = contentHeight - (offsetY+boundsHeight)
		if diff > 10 {
			return .none
		}
        return .atBottom
	}

	func isNear(_ edge: VerticalEdge) -> Bool {
		switch edge {
		case .top:
			offsetY < boundsHeight / 2
		case .bottom:
			offsetY > (bottomMostOffset - (boundsHeight / 2))
		}
	}
}

// MARK: - ScrollPositionValue

@frozen
public indirect enum ScrollPositionValue: Hashable {
	case y(CGFloat)
	case id(String?, anchor: UnitPoint)
	case edge(Edge)
}

// MARK: - ScrollPositionItem

@frozen
public struct ScrollPositionItem: Hashable {
	public let position: ScrollPositionValue
	public let properties: Properties

	public enum Properties: Hashable, Equatable {
        case animated(Animation = .linearSmooth)
		case notAnimated
		case scroll
	}

	public init(_ position: ScrollPositionValue, properties: Properties) {
		self.position = position
		self.properties = properties
	}

	public static func y(_ value: CGFloat, _ properties: Properties = .notAnimated) -> Self {
		.init(.y(value), properties: properties)
	}

	public static func id(_ value: String?, anchor: UnitPoint = .bottom, _ properties: Properties = .notAnimated) -> Self {
		.init(.id(value, anchor: anchor), properties: properties)
	}

	public static func edge(_ value: Edge, _ properties: Properties = .notAnimated) -> Self {
		.init(.edge(value), properties: properties)
	}
}

// MARK: - ScrolledPosition

@frozen
public enum ScrolledPosition: Sendable, Hashable {
	case none
	case atBottom
	case belowBottom(_ offset: CGFloat)
	case atTop
}
