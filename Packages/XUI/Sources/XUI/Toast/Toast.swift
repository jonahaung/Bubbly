//
//  Toast.swift
//  XUI
//
//  Created by Aung Ko Min on 18/10/25.
//

import Foundation

public struct Toast: Sendable, Identifiable, Hashable {
    public var id: UUID = .init()
    public var message: String
    public var duration: Double
    public var actionTitle: String?
    public var style: ToastStyle = .default

    public var action: (@MainActor @Sendable () -> Void)?

    public init(
        id: UUID = UUID(),
        message: String,
        duration: Double = 5,
        style: ToastStyle = .default,
        actionTitle: String? = nil,
        action: (@MainActor @Sendable () -> Void)? = nil
    ) {
        self.id = id
        self.message = message
        self.duration = duration
        self.style = style
        self.actionTitle = actionTitle
        self.action = action
    }

    public static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id &&
            lhs.message == rhs.message &&
            lhs.duration == rhs.duration &&
            lhs.style == rhs.style &&
            lhs.actionTitle == rhs.actionTitle
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(message)
        hasher.combine(duration)
        hasher.combine(style)
        hasher.combine(actionTitle)
    }
}
