//
//  GeometryProxy+Extensions.swift
//  XUI
//
//  Created by Aung Ko Min on 1/12/25.
//

import SwiftUI

public extension GeometryProxy {
	var globalFrame: CGRect {
		frame(in: .global)
	}
}

public extension GeometryProxy {
	var insetAdjustedSize: CGSize {
		.init(
			width: size.width - (safeAreaInsets.leading + safeAreaInsets.trailing),
			height: size.height - (safeAreaInsets.top + safeAreaInsets.bottom)
		)
	}

	var ignoreSafeAreaSize: CGSize {
		.init(
			width: size.width + (safeAreaInsets.leading + safeAreaInsets.trailing),
			height: size.height + (safeAreaInsets.top + safeAreaInsets.bottom)
		)
	}
}
