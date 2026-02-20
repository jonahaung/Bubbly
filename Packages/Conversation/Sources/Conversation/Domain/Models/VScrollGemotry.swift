import SwiftUI
import XUI

public struct VScrollGeometry: Sendable, Hashable {
	public let contentHeight: CGFloat
	public let boundsHeight: CGFloat
	public var offsetY: CGFloat
	public let topInset: CGFloat
	public let bottomInset: CGFloat
}

public extension VScrollGeometry {
	init(_ geometry: ScrollGeometry) {
		self.init(
			contentHeight: geometry.contentSize.height.rounded(toPlaces: 1),
			boundsHeight: geometry.bounds.height.rounded(toPlaces: 1),
			offsetY: geometry.contentOffset.y.rounded(toPlaces: 1) + geometry.contentInsets.top.rounded(toPlaces: 1),
			topInset: geometry.contentInsets.top.rounded(toPlaces: 1),
			bottomInset: geometry.contentInsets.bottom.rounded(toPlaces: 1)
		)
	}

	static let empty = VScrollGeometry(
		contentHeight: .zero,
		boundsHeight: .zero,
		offsetY: .zero,
		topInset: .zero,
		bottomInset: .zero
	)
}

public extension VScrollGeometry {
	var bottomMostOffset: CGFloat {
		contentHeight - boundsHeight
	}
	var scrolledPosition: ScrolledPosition {
		if offsetY == 0 {
			return .atTop
		}
		if offsetY+boundsHeight == contentHeight {
			return .atBottom
		}
		return .none
	}
}
