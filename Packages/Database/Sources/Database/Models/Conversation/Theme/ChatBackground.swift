// © 2026 Aung Ko Min

import SwiftUI
import XUI

// MARK: - ChatBackground

public enum ChatBackground: Int, Codable, CaseIterable, Sendable {
    case `default`
    case system
    case group
}

// MARK: Identifiable

extension ChatBackground: Identifiable {
    public var id: Int {
        rawValue
    }

    public var color: Color {
        switch self {
        case .default:
            .background
        case .group:
            .systemGroupedBackground
        case .system:
            .appPrimary
        }
    }
}

// MARK: XPickable, EmptyRepresentable

extension ChatBackground: XPickable, EmptyRepresentable {
    public var title: String {
        String(describing: self)
    }

    public static var empty: Database.ChatBackground {
        .default
    }
}
