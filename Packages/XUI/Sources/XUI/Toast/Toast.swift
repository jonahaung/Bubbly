//
//  Toast.swift
//  XUI
//
//  Created by Aung Ko Min on 18/10/25.
//

import SwiftUI

@MainActor
public struct Toast: Sendable, @MainActor Identifiable, @MainActor Hashable {

	public let id: AnyHashable
	public let node: any RenderNode
	public let duration: Double
	public let style: ToastStyle

	public init(
		node: any RenderNode,
		duration: Double = 5,
		style: ToastStyle = .top,
		action: (@MainActor @Sendable () -> Void)? = nil
	) {
		self.id = node.renderID()
		self.node = node
		self.duration = duration
		self.style = style
	}

	public init(
		message: String,
		duration: Double = 5,
		style: ToastStyle = .top,
		actionTitle: String? = nil,
	) {
		self.init(
			node: Text(message).opaqueView(),
			duration: duration,
			style: style
		)
	}
	public static func == (lhs: Toast, rhs: Toast) -> Bool {
		lhs.id == rhs.id &&
		lhs.node.renderID() == rhs.node.renderID() &&
		lhs.duration == rhs.duration &&
		lhs.style == rhs.style
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(node.renderID())
		hasher.combine(duration)
		hasher.combine(style)
	}
}
