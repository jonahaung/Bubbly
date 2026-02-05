//
//  GeometryProxy++.swift
//  XUI
//
//  Created by Aung Ko Min on 1/12/25.
//

import SwiftUI

extension GeometryProxy {
	public var globalFrame: CGRect {
		frame(in: .global)
	}
}
extension GeometryProxy {
	public var insetAdjustedSize: CGSize {
		.init(
			width: size.width - (safeAreaInsets.leading + safeAreaInsets.trailing),
			height: size.height - (safeAreaInsets.top + safeAreaInsets.bottom)
		)
	}
	public var ignoreSafeAreaSize: CGSize {
		.init(
			width: size.width + (safeAreaInsets.leading + safeAreaInsets.trailing),
			height: size.height + (safeAreaInsets.top + safeAreaInsets.bottom)
		)
	}
}
