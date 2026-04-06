//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI
import XUI

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

	@MainActor
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
		contentHeight - boundsHeight + topInset
	}

	var scrolledPosition: ScrolledPosition {
		if offsetY.rounded() == 0 {
			return .atTop
		}
		if (offsetY + boundsHeight).rounded() == contentHeight.rounded() {
			return .atBottom
		}
		return .none
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
