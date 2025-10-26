//
//  BadgeView.swift
//  XUI
//
//  Created by Aung Ko Min on 13/9/25.
//

import SwiftUI

extension View {
	public func badgeView<Content>(_ content: Content) -> some View where Content: View {
		overlay(
			ZStack {
				content
			}
				.alignmentGuide(.top) { $0.height / 2 }
				.alignmentGuide(.trailing) { $0.width / 2 }
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
		)
	}
}
