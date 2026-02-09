//
//  VLabel.swift
//
//
//  Created by Aung Ko Min on 23/4/23.
//

import SwiftUI

public struct VLabel<Top: View, Bottom: View>: View {
	private let spacing: CGFloat
	private var top: () -> Top
	private var bottom: () -> Bottom

	public init(spacing: CGFloat = 5,
	            @ViewBuilder top: @escaping () -> Top,
	            @ViewBuilder bottom: @escaping () -> Bottom)
	{
		self.spacing = spacing
		self.top = top
		self.bottom = bottom
	}

	public init(spacing: CGFloat = 5, iconName: String, text: String) {
		self.spacing = spacing
		top = {
			if let image = Image(systemName: iconName) as? Top {
				image
			} else {
				fatalError("Could not cast Image to Top type")
			}
		}
		bottom = {
			if let textView = Text(text) as? Bottom {
				textView
			} else {
				fatalError("Could not cast Text to Bottom type")
			}
		}
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: spacing) {
			top()
				.imageScale(.small)
			bottom()
		}
	}
}
