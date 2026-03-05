//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import SwiftUI
import XUI

public struct ChatTheme: Sendable, Equatable, EmptyRepresentable {
    struct Theme: Equatable {
        let bubbleCoor: Color
        let shadowColor: Color
        let foregroundStyle: Color
    }

    let outgoing: Theme
    let incoming: Theme
    let backgroundColor: Color
    let bubbleCornerRadius: CGFloat
    let bubblePading: EdgeInsets
    let font: Font
    let secondaryColor: Color

    public init(_ theme: Database.ConversationTheme) {
        backgroundColor = theme.background.color
        secondaryColor = BubbleColor.allCases.random().value
        outgoing = .init(
            bubbleCoor: theme.outgoingBubbleColor,
            shadowColor: Color(white: 0.85),
            foregroundStyle: .darkText
        )
        incoming = .init(
            bubbleCoor: theme.incomingBubbleColor,
            shadowColor: Color(white: 0.8),
            foregroundStyle: .primary
        )
        let uiFont = UIFont.preferredFont(forTextStyle: .body)
        font = .system(size: uiFont.pointSize)
        let verticalPadding = uiFont.chatVerticalPadding
        let horizontalPadding = uiFont.chatHorizontalPadding
        bubblePading = .init(
            top: verticalPadding,
            leading: horizontalPadding,
            bottom: verticalPadding,
            trailing: horizontalPadding
        )
        bubbleCornerRadius = max(16, uiFont.lineHeight * 0.75)
    }

    public static let empty = ChatTheme(.default)

    public func bubbleColor(for isSender: Bool) -> some ShapeStyle {
        isSender ? outgoing.bubbleCoor : incoming.bubbleCoor
    }

    public func foregroundStyle(for isSender: Bool) -> some ShapeStyle {
        isSender ? outgoing.foregroundStyle : incoming.foregroundStyle
    }

    public func shadowColor(for isSender: Bool) -> some ShapeStyle {
        isSender ? outgoing.shadowColor : incoming.shadowColor
    }
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

//
// extension ConversationTheme {
//	public func bubbleColor(for isSender: Bool) -> some ShapeStyle {
//		isSender ? outgoingBubbleColor : incomingBubbleColor
//	}
//
//	public func foregroundStyle(for isSender: Bool) -> some ShapeStyle {
//		isSender ? Color.darkText : .primary
//	}
//
//	public func shadowColor(for isSender: Bool) -> some ShapeStyle {
//		isSender ? outgoingBubbleColor
//			.darker(byPercentage: 10) : incomingBubbleColor
//			.darker(byPercentage: 10)
//	}
//	public var uiFont: UIFont { UIFont.preferredFont(forTextStyle: .body) }
//	public var font: Font { .system(size: uiFont.pointSize) }
//	public var bubblePading: EdgeInsets {
//		let verticalPadding = uiFont.chatVerticalPadding
//		let horizontalPadding = uiFont.chatHorizontalPadding
//		return .init(
//		top: verticalPadding,
//		leading: horizontalPadding,
//		bottom: verticalPadding,
//		trailing: horizontalPadding
//	)}
// }
