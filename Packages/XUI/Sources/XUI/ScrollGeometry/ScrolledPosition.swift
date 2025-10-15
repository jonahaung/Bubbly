//
//  ScrollingState.swift
//  XUI
//
//  Created by Aung Ko Min on 28/2/25.
//

import Foundation
import SwiftUI

public struct ScrollLocation {

	public let fraction: CGFloat
	public let edge: VerticalEdge

	public init(edge: VerticalEdge, fraction: CGFloat) {
		self.fraction = fraction
		self.edge = edge
	}

	public var edgeDescription: String {
		switch edge {
		case .top:
			return "Top"
		case .bottom:
			return "Bottom"
		}
	}
}

public enum ScrollDirection: Sendable {
	case isGoingDown, isGoingUp, none
	var isScrolling: Bool {
		self != .none
	}
}
public enum ScrollPositionItem: Hashable, Sendable {
	case offset(yPosition: CGFloat, animated: Bool)
	case id(value: String, anchor: UnitPoint?, animated: Bool)
	case bottom(animated: Bool)
}
public enum ScrolledPosition: Sendable, Hashable {
	case none
	case atBottom
	case atTop
	case position(_ edge: VerticalEdge, _ fraction: CGFloat)

	public init(_ geometry: ScrollGeometry) {
		let contentHeight = geometry.contentSize.height
		let topSpace = geometry.topSpace
		let bottomSpace = geometry.bottomSpace
		switch (topSpace, bottomSpace) {
		case (_, let bottom) where bottom <= -geometry.contentInsets.bottom :
			self = .atBottom
		case (let top, _) where top <= -geometry.contentInsets.top:
			self = .atTop
		default:
			let center = geometry.centerLocation
			let edge = center < 0.5 ? VerticalEdge.top : .bottom
			let fraction = edge == .top ? (geometry.visibleRect.minY / contentHeight) : 1 - (geometry.visibleRect.maxY / contentHeight)
			self = .position(edge, fraction)
		}
	}

	public var isAroundBottom: Bool {
		switch self {
		case .atBottom:
			return true
		case .position(let edge, let frraction):
			switch edge {
			case .top:
				return false
			case .bottom:
				return frraction < 0.001
			}
		default:
			return false
		}
	}
}

public extension ScrollGeometry {
	var scrolledPosition: ScrolledPosition {
		ScrolledPosition(self)
	}
	var location: ScrollLocation {
		let edge = centerLocation < (0.45) ? VerticalEdge.top : .bottom
		switch edge {
		case .top:
			return .init(edge: edge, fraction: visibleRect.minY/contentSize.height)
		case .bottom:
			return .init(edge: edge, fraction: 1 - (visibleRect.maxY/contentSize.height))
		}
	}
}

public extension ScrollPosition {
	mutating func stopScrolling(_ scrollGeometry: ScrollGeometry) {
		scrollTo(y: scrollGeometry.contentOffset.y, within: scrollGeometry)
	}
	mutating func scrollToBottom(_ scrollGeometry: ScrollGeometry) {
		scrollTo(y: scrollGeometry.bottomMostOffset, within: scrollGeometry)
	}
	mutating func adjust(from oldValue: ScrollGeometry, to newValue: ScrollGeometry, edge: VerticalEdge) {
		let proposedOffset = newValue.adjustedOffsetY(from: oldValue, edge: edge)
		self = .init(y: proposedOffset)
		//		scrollTo(y: proposedOffset, within: newValue)
	}

	mutating func scrollTo(y: CGFloat, within scrollGeometry: ScrollGeometry) {
		let clamped = min(max(0, y), scrollGeometry.bottomMostOffset)
		scrollTo(y: clamped)
	}

	var viewID: String? {
		self.viewID(type: String.self)
	}
}

public extension ScrollGeometry {
	var absContentHeight: CGFloat {
		contentSize.height - contentInsets.vertical
	}
	func adjustedOffsetY(from oldValue: ScrollGeometry, edge: VerticalEdge) -> CGFloat {
		guard contentSize.height > 0 else { return contentInsets.top }
		let diffHeight = (oldValue.contentSize.height - contentSize.height) + (oldValue.contentOffset.y - contentOffset.y)
		guard diffHeight != 0 else {
			return contentOffset.y
		}
		let offsetY = oldValue.visibleRect.minY - diffHeight
		let adjustedY = edge == .top ? offsetY - -contentInsets.top : offsetY
		return adjustedY
	}

	func isCloseToBottom(threshold: CGFloat = 0.01) -> Bool {
		guard self.contentSize.height > 0 else { return true }
		let bottomPosition = (visibleRect.maxY / contentSize.height)
		return bottomPosition > (1 - threshold)
	}

	func isCloseToTop(threshold: CGFloat = 0.01) -> Bool {
		guard self.contentSize.height > 0 else { return true }
		let topPosition = (visibleRect.minY / contentSize.height)
		return topPosition < threshold
	}
	var centerLocation: CGFloat {
		(visibleRect.midY / contentSize.height)
	}
}
