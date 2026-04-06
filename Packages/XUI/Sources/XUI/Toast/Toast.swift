//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@MainActor
public struct Toast: @MainActor Identifiable, @MainActor Hashable {
    public let id: AnyHashable
    public let node: any RenderNode
    public let duration: Double
    public let style: ToastStyle
    public let allowsBackgroundTap: Bool
    public let action: (@MainActor @Sendable () -> Void)?

    public init(
        node: any RenderNode,
        duration: Double = 5,
        style: ToastStyle = .top,
        allowsBackgroundTap: Bool,
        action: (@MainActor @Sendable () -> Void)? = nil
    ) {
		id = UUID().uuidString
        self.node = node
        self.duration = duration
        self.style = style
        self.allowsBackgroundTap = allowsBackgroundTap
        self.action = action
    }

    public init(
        message: String,
        duration: Double = 5,
        style: ToastStyle = .top,
        allowsBackgroundTap: Bool
    ) {
        self.init(
            node: Text(.init(message)).opaqueView(),
            duration: duration,
            style: style, allowsBackgroundTap: allowsBackgroundTap
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
