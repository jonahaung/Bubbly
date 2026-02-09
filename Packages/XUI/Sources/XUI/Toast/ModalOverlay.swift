//
//  ModalOverlay.swift
//  XUI
//
//  Created by Aung Ko Min on 3/2/26.
//

import SwiftUI

public struct ModalOverlay<Content: View>: View {
	private let alignment: Alignment
	private let edge: Edge
	@ViewBuilder private let content: () -> Content
	private let onClose: () -> Void

	public init(_ alignment: Alignment,
	            from edge: Edge,
	            @ViewBuilder _ content: @escaping () -> Content,
	            onClose: @escaping () -> Void)
	{
		self.alignment = alignment
		self.edge = edge
		self.content = content
		self.onClose = onClose
	}

	public var body: some View {
		ModalContentView(alignment, {
			content()
		}, onClose: onClose)
			.transition(
				.asymmetric(
					insertion: .move(edge: edge, curve: .interpolatingSpring(duration: 0.4)),
					removal: .move(edge: edge, curve: .linear)
				)
			)
	}
}

public struct ModalContentView<Content: View>: View {
	private let alignment: Alignment
	@ViewBuilder private let content: () -> Content
	private let onClose: () -> Void
	@Environment(\.dismiss) private var dismiss
	public init(_ alignment: Alignment,
	            @ViewBuilder _ content: @escaping () -> Content,
	            onClose: @escaping () -> Void)
	{
		self.alignment = alignment
		self.content = content
		self.onClose = onClose
	}

	public var body: some View {
		ZStack(alignment: alignment) {
			Color.clear
				.contentShape(ContainerRelativeShape())
				.ignoresSafeArea()
				.backgroundExtensionEffect()
				.gesture(backgroundTapGesture)
			content()
		}
	}

	private var backgroundTapGesture: some Gesture {
		TapGesture().onEnded {
			onClose()
		}
	}
}
