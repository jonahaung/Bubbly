//
//  ScrollGeometry++.swift
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
		return min(contentSize.height, max(0, contentSize.height - bounds.height))
	}
}
