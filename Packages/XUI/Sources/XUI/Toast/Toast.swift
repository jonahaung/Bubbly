//  Toast.swift
//
//  Copyright © 2025 Aung Ko Min.
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
        duration: Double = 3,
        style: ToastStyle,
        allowsBackgroundTap: Bool = true,
        action: (@MainActor @Sendable () -> Void)? = nil
    ) {
        id = UUID().uuidString
        self.node = node
        self.duration = duration
        self.style = style
        self.allowsBackgroundTap = allowsBackgroundTap
        self.action = action
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
