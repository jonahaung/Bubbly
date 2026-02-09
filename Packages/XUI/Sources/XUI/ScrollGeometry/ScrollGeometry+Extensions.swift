//
//  ScrollGeometry+Extensions.swift
//  XUI
//
//  Created by Aung Ko Min on 28/2/25.
//

import SwiftUI

public extension ScrollGeometry {
	var topSpace: CGFloat {
		visibleRect.minY
	}

	var bottomSpace: CGFloat {
		if containerSize.height > contentSize.height {
			return 0
		}
		return contentSize.height - visibleRect.maxY
	}

	var bottomMostOffset: CGFloat {
		guard contentSize.height > 0 else {
			return 0
		}
		return contentSize.height + contentInsets.bottom - bounds.height
	}

	func targetOffsetYForRect(target rect: CGRect) -> CGFloat {
		let targetY = rect.maxY + contentInsets.bottom - bounds.height
		let minOffsetY = contentInsets.top
		let maxOffsetY = bottomMostOffset
		return min(max(targetY, minOffsetY), maxOffsetY)
	}

	var isScrolledAtBottom: Bool {
		(bottomMostOffset - contentInsets.vertical).rounded() == contentOffset.y.rounded()
	}
}
