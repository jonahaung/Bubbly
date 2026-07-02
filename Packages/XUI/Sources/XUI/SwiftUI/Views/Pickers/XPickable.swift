//  XPickable.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

// public struct XBadge: Hashable, Sendable, Identifiable {
//	public var id: String { systemName }
//	public let systemName: String
//	public let color: Color
//
//	public init(systemName: String, color: Color) {
//		self.systemName = systemName
//		self.color = color
//	}
// }

public protocol XPickable: Hashable, Identifiable, Sendable, EmptyRepresentable, CaseIterable {
    var title: String { get }
    @MainActor
    var badge: RenderNode? { get }
}

public extension XPickable {
    var badge: RenderNode? {
        nil
    }
}

extension XPickable {
    var isEmpty: Bool {
        self == Self.empty
    }
}

public protocol EmptyRepresentable: Sendable {
    static var empty: Self { get }
}

extension String: @retroactive CaseIterable {}
extension String: XPickable {
    public static var allCases: [String] {
        [""]
    }

    public static var empty: String {
        ""
    }

    public var title: String {
        replacingOccurrences(of: "_", with: " ").capitalized
    }
}
