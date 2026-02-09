//
//  XRadioPicker.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 12/8/23.
//

import SwiftUI

public struct XRadioPicker<Item: XPickable>: View {
	private let items: [Item]
	private var selection: Binding<Item>

	/// Keep external labels for source compatibility, but use valid identifiers
	public init(_ items: [Item], _ selection: Binding<Item>) {
		self.items = items
		self.selection = selection
	}

	public var body: some View {
		Group {
			ForEach(items) { item in
				AsyncButton {
					Haptics.play(.rigid, 0.9)
					selection.wrappedValue = item
				} label: {
					HStack {
						SystemImage(item == selection.wrappedValue ? .circleInsetFilled : .circle)
						Text(item.title)
							.accentColor(.primary)
					}
				}
			}
		}
	}
}
