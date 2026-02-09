//
//  Flexible.swift
//
//
//  Created by Aung Ko Min on 14/5/23.
//

import SwiftUI

private struct FlexibleModifier: ViewModifier {
	let edge: Edge.Set
	func body(content: Content) -> some View {
		content
			.frame(
				maxWidth: edge == .horizontal ? .infinity : nil,
				maxHeight: edge == .vertical ? .infinity : nil
			)
	}
}

public extension View {
	func flexible(_ edge: Edge.Set) -> some View {
		ModifiedContent(content: self, modifier: FlexibleModifier(edge: edge))
	}
}
