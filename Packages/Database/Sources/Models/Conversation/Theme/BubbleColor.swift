//
//  BubbleColor.swift
//  UI
//
//  Created by Aung Ko Min on 16/2/25.
//

import SwiftUI
import XUI

public enum BubbleColor: String, Sendable, Hashable, CaseIterable, Codable, Identifiable {
    case `default`, whatsApp, skyBlue, babyPink
    case mistyRose, paleTurquoise, mintCream, warmBeige, aqua
    case lavender, lilac, blush, lemon, sage, mint, periwinkle
    case peach, coral, sand, olive, teal, navy
    case lightGray

    public var id: String { rawValue }

    public var value: Color {
        Self.colorMap[self] ?? .gray
    }

    private static let colorMap: [BubbleColor: Color] = [
        // MARK: - Basics

        .default: .init(red: 1.0, green: 1.0, blue: 1.0),
        .whatsApp: .init(red: 0.85, green: 1.0, blue: 0.85),

        // MARK: - Blues

        .skyBlue: .init(red: 0.81, green: 0.90, blue: 0.95),
        .aqua: .init(red: 0.75, green: 0.88, blue: 0.90),
        .periwinkle: .init(red: 0.85, green: 0.90, blue: 0.96),
        .teal: .init(red: 0.6, green: 0.85, blue: 0.85),
        .navy: .init(red: 0.35, green: 0.45, blue: 0.65),

        // MARK: - Greens

        .mint: .init(red: 0.80, green: 0.96, blue: 0.88),
        .mintCream: .init(red: 0.88, green: 0.94, blue: 0.85),
        .sage: .init(red: 0.78, green: 0.84, blue: 0.70),
        .paleTurquoise: .init(red: 0.87, green: 0.99, blue: 1.0),
        .olive: .init(red: 0.75, green: 0.78, blue: 0.55),

        // MARK: - Purples / Lilacs

        .lavender: .init(red: 0.93, green: 0.90, blue: 0.98),
        .lilac: .init(red: 0.90, green: 0.88, blue: 0.96),

        // MARK: - Reds / Pinks

        .babyPink: .init(red: 1.0, green: 0.86, blue: 0.90),
        .blush: .init(red: 0.99, green: 0.88, blue: 0.89),
        .mistyRose: .init(red: 1.0, green: 0.89, blue: 0.88),
        .coral: .init(red: 1.0, green: 0.78, blue: 0.75),
        .peach: .init(red: 1.0, green: 0.90, blue: 0.80),

        // MARK: - Yellows / Beiges

        .lemon: .init(red: 0.99, green: 0.96, blue: 0.87),
        .warmBeige: .init(red: 0.98, green: 0.88, blue: 0.79),
        .sand: .init(red: 0.96, green: 0.91, blue: 0.78),

        // MARK: - Grays / Neutrals

        .lightGray: .init(red: 0.93, green: 0.93, blue: 0.93)
    ]
}

extension BubbleColor: XPickable, EmptyRepresentable {
    var color: Color {
        value
    }

    public var title: String {
        rawValue
    }

    public static var empty: BubbleColor {
        .default
    }
}
