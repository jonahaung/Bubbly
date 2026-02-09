//
//  HighlightedTextDemo.swift
//  XUI
//
//  Created by Aung Ko Min on 1/2/26.
//

import SwiftUI

public struct HighlightedTextDemo: View {
	public init() {}
	public var body: some View {
		VStack(spacing: 24) {
			HighlightedText(
				text: "Hello World, welcome to SwiftUI TextRenderer!",
				highlightedText: "World"
			)

			HighlightedText(
				text: "Search results highlight matching keywords",
				highlightedText: "highlight",
				shapeStyle: .orange.opacity(0.4)
			)

			HighlightedText(
				text: "Pure SwiftUI. No NSAttributedString.",
				highlightedText: "SwiftUI",
				shapeStyle: LinearGradient(
					colors: [.pink, .purple],
					startPoint: .leading,
					endPoint: .trailing
				)
			)
		}
		.padding()
	}
}

#Preview {
	HighlightedTextDemo()
}
