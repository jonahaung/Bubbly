import SwiftUI
import XUI

public struct VScrollGeometry: Sendable, Hashable {
	public let contentHeight: CGFloat
	public let boundsHeight: CGFloat
	public let offsetY: CGFloat
	public let topInset: CGFloat
	public let bottomInset: CGFloat
}

extension VScrollGeometry {
	public init(_ geometry: ScrollGeometry) {
		self.init(
			contentHeight: geometry.contentSize.height,
			boundsHeight: geometry.bounds.height,
			offsetY: geometry.contentOffset.y + geometry.contentInsets.top,
			topInset: geometry.contentInsets.top,
			bottomInset: geometry.contentInsets.bottom
		)
	}
	public static let empty = VScrollGeometry(
		contentHeight: .zero,
		boundsHeight: .zero,
		offsetY: .zero,
		topInset: .zero,
		bottomInset: .zero
	)
}

extension VScrollGeometry {
	public var bottomMostOffset: CGFloat {
		contentHeight - boundsHeight
	}
	public var scrolledPosition: ScrolledPosition {
		if offsetY.rounded() == 0 {
			return .atTop
		}
		if (offsetY + boundsHeight).rounded() == contentHeight.rounded() {
			return .atBottom
		}
		return .none
	}
}
