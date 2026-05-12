//  ChatTheme.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database

// MARK: - ChatTheme

public struct ChatTheme: Sendable, Equatable, EmptyRepresentable {

    public init(_ theme: Database.ConversationTheme) {
        backgroundColor = Color.background
        secondaryColor = Color.tint
        outgoing = .init(
            bubbleCoor: theme.bubbleColor.value
        )
        incoming = .init(
            bubbleCoor: Color.container
        )
        let uiFont = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .regular)
        font =
            .system(size: UIFont.labelFontSize, weight: .regular, design: .default)
        let verticalPadding = uiFont.chatVerticalPadding
        let horizontalPadding = uiFont.chatHorizontalPadding
        bubblePading = .init(
            top: verticalPadding,
            leading: horizontalPadding,
            bottom: verticalPadding,
            trailing: horizontalPadding
        )
        bubbleCornerRadius = theme.bubbleCornorRadius
    }

    // MARK: Public

    public static let empty: ChatTheme = .init(.default)

    public func bubbleColor(for isSender: Bool) -> Color {
        isSender ? outgoing.bubbleCoor : incoming.bubbleCoor
    }

    public func shadowColor(for _: Bool) -> Color {
        Color.shadow
    }

    public func shadowPadding(for isSender: Bool) -> EdgeInsets {
        .init(
            top: 0.2,
            leading: isSender ? 1 : 0.2,
            bottom: 1,
            trailing: isSender ? 0.2 : 1
        )
    }

    struct Theme: Equatable {
        let bubbleCoor: Color
    }

    let outgoing: Theme
    let incoming: Theme
    let backgroundColor: Color
    let bubbleCornerRadius: CGFloat
    let bubblePading: EdgeInsets
    let font: Font
    let secondaryColor: Color
}

extension UIFont {
    var chatOpticalOffset: CGFloat {
        let topExtra = ascender - capHeight // space above capital letters
        let bottom = abs(descender)
        return (topExtra * 0.18) - (bottom * 0.06)
    }

    var chatVerticalPadding: CGFloat {
        max(10, lineHeight * 0.34)
    }

    var chatHorizontalPadding: CGFloat {
        max(12, lineHeight * 0.55)
    }
}
