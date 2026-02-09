//
//  StretchyHeaderScrollView.swift
//
//
//  Created by Aung Ko Min on 31/5/24.
//

import SwiftUI

@available(iOS 18.0, *)
public struct StretchyHeaderScrollView<Content: View, Header: View>: View {
	private let showsIndicators: Bool
	private let headerHeight: CGFloat
	private let multiplier: CGFloat
	private let content: () -> Content
	private let header: () -> Header

	@State private var scrollViewOffset: CGFloat = 0

	public init(showsIndicators: Bool = false,
	            headerHeight: CGFloat,
	            multipliter: CGFloat,
	            @ViewBuilder content: @escaping () -> Content,
	            @ViewBuilder header: @escaping () -> Header)
	{
		self.showsIndicators = showsIndicators
		self.headerHeight = headerHeight
		multiplier = multipliter
		self.content = content
		self.header = header
	}

	public var body: some View {
		ZStack(alignment: .top) {
			header()
				.offset(y: scrollViewOffset > 0 ? -scrollViewOffset * multiplier : 0)
				.scaleEffect(
					scrollViewOffset < 0 ? (headerHeight - scrollViewOffset) / headerHeight : 1,
					anchor: .top
				)
			ScrollView(.vertical, showsIndicators: showsIndicators) {
				content()
			}
			.onScrollGeometryChange(for: CGFloat.self, of: { geometry in
				geometry.contentOffset.y + geometry.contentInsets.top
			}, action: { oldValue, newValue in
				// Coalesce micro updates to avoid multiple per-frame state writes
				guard abs(newValue - oldValue) > 0.5 else { return }
				scrollViewOffset = newValue
			})
		}
	}
}
