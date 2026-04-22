//  ChatBackground.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import XUI
import SwiftUI

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
        case .bg_1: "bg_1"
        case .bg_2: "bg_2"
        case .bg_3: "bg_3"
        case .bg_4: "bg_4"
        case .bg_5: "bg_5"
        case .bg_6: "bg_6"
        case .bg_7: "bg_7"
        case .bg_8: "bg_8"
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
