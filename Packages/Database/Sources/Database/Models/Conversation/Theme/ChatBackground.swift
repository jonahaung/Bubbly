// © 2026 Aung Ko Min

import SwiftUI
import XUI

// MARK: - ChatBackground

public enum ChatBackground: Int, Codable, CaseIterable, Sendable {
    case bg_1
    case bg_2
    case bg_3
    case bg_4
    case bg_5
    case bg_6
    case bg_7
    case bg_8
}

// MARK: Identifiable

extension ChatBackground: Identifiable {
    public var id: Int {
        rawValue
    }

    public var imageName: String {
        switch self {
        case .bg_1: return "bg_1"
        case .bg_2: return "bg_2"
        case .bg_3: return "bg_3"
        case .bg_4: return "bg_4"
        case .bg_5: return "bg_5"
        case .bg_6: return "bg_6"
        case .bg_7: return "bg_7"
        case .bg_8: return "bg_8"
        }
    }
    
    public var `default`: Self { .bg_6 }
}

// MARK: XPickable, EmptyRepresentable

extension ChatBackground: XPickable, EmptyRepresentable {
    public var title: String {
        String(describing: self)
    }

    public static var empty: Database.ChatBackground {
        .bg_6
    }
}
