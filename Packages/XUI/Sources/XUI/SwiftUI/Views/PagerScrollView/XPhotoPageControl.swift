//
//  XPhotoPageControl.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 4/7/23.
//

import SwiftUI

public struct XPhotoPageControl: View {
	@Binding private var selection: String
	private let items: [String]
	private let size: CGFloat
	@Namespace private var namespace

	public init(selection: Binding<String>, items: [String], size: CGFloat) {
		_selection = selection
		self.items = items
		self.size = size
	}

	public var body: some View {
		HStack(alignment: .bottom, spacing: 0.5) {
			ForEach(items, id: \.self) { item in
				let isSelected = selection == item
				if isSelected {
					Image(systemName: "\(items.firstIndex(of: item) ?? 0 + 1).circle.fill")
						.resizable()
						.scaledToFit()
						.frame(square: size)
						.matchedTransitionSource(id: item, in: namespace)
				} else {
					Image(systemName: "\(items.firstIndex(of: item) ?? 0 + 1).circle")
						.resizable()
						.scaledToFit()
						.frame(square: size / 1.5)
						.matchedTransitionSource(id: item, in: namespace)
				}
			}
		}
		.animation(.snappy, value: selection)
		.geometryGroup()
	}
}
