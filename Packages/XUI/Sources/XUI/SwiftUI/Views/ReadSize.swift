//
//  ReadSize.swift
//  XUI
//
//  Created by Aung Ko Min on 23/9/25.
//

import SwiftUI

public extension View {
	func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
		background(
			GeometryReader { geometryProxy in
				Color.clear
					.preference(key: SizePreferenceKey.self, value: geometryProxy.size)
			}
		)
		.onPreferenceChange(SizePreferenceKey.self, perform: onChange)
	}
}

struct SizePreferenceKey: PreferenceKey {
	nonisolated(unsafe) static var defaultValue: CGSize = .zero
	static func reduce(value _: inout CGSize, nextValue _: () -> CGSize) {}
}
