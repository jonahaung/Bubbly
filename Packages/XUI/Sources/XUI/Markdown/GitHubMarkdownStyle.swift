//  GitHubMarkdownStyle.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import UIKit
import SwiftUI
import Foundation

public struct GitHubMarkdownStyle {

    public init() {}

    public var base: AttributeContainer = .paragraph

    public func block(
        _ kind: PresentationIntent.Kind
    ) -> AttributeContainer {
        switch kind {
        case let .header(level):
            let size =
                UIFont.preferredFont(forTextStyle: .title1).pointSize
                    - CGFloat(level * 2)
            let font = Font.system(
                size: size,
                weight: .semibold,
                design: .default
            ).width(.condensed)
            return .init()
                .font(font)
                .foregroundColor(Color.primaryText)
                .lineHeight(.multiple(factor: 1.3))
                .paragraphStyle(.default)
        case .listItem,
             .orderedList,
             .unorderedList:
            return .init()
                .font(.system(size: labelFontSize, design: .rounded))
                .foregroundColor(Color.primaryText)
                .lineHeight(.multiple(factor: 1.4))
                .paragraphStyle(.default)
        case .codeBlock:
            return .init()
                .font(
                    .system(
                        size: systemFontSize,
                        weight: .medium,
                        design: .monospaced
                    )
                    .width(.compressed)
                )
                .foregroundColor(.secondaryText)
        case .blockQuote:
            return .init()
                .font(
                    .system(
                        size: systemFontSize + 2,
                        weight: .thin,
                        design: .serif
                    )
                )
                .foregroundColor(.secondaryText)
                .paragraphStyle(.default)
        case .paragraph:
            return .paragraph
                .foregroundColor(Color.appPrimary)
        case .thematicBreak:
            return .init()
                .lineHeight(.multiple(factor: 1))
                .foregroundColor(.tertiaryText)
        default:
            return .paragraph
        }
    }

    private var labelFontSize: CGFloat {
        UIFont.labelFontSize
    }

    private var systemFontSize: CGFloat {
        UIFont.systemFontSize
    }
}

extension NSParagraphStyle: @unchecked @retroactive Sendable {
    public static let `default`: NSParagraphStyle = { paragraphStyle in
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineBreakStrategy = .pushOut
        paragraphStyle.allowsDefaultTighteningForTruncation = false
        paragraphStyle.alignment = .natural
        paragraphStyle.lineSpacing = 1
        paragraphStyle.lineHeightMultiple = 1.3
        return paragraphStyle
    }(NSMutableParagraphStyle())
}

extension AttributeContainer {
    static let paragraph: AttributeContainer = {
        var container = AttributeContainer()
        container.font = Typography.system.body
        container.lineHeight = .multiple(factor: 1.3)
        container.paragraphStyle = .default
        return container
    }()
}
