//  GitHubMarkdownStyle.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI
import Foundation

extension NSParagraphStyle: @unchecked @retroactive Sendable {}

public struct GitHubMarkdownStyle: Sendable {
    public let base: AttributeContainer

    public init() {
        base = .markdownParagraph
    }

    public init(base: AttributeContainer) {
        self.base = base
    }

    public func block(
        _ kind: PresentationIntent.Kind
    ) -> AttributeContainer {
        switch kind {
        case let .header(level):
            let pointSize = UIFont.preferredFont(forTextStyle: .title1).pointSize
                - CGFloat(level.clamped(to: 1 ... 6) * 2)
            return AttributeContainer()
                .font(
                    .system(
                        size: pointSize,
                        weight: .semibold,
                        design: .default
                    )
                    .width(.condensed)
                )
                .foregroundColor(.primaryText)
                .lineHeight(.multiple(factor: 1.3))
                .paragraphStyle(Self.paragraphStyle())
        case .listItem,
             .orderedList,
             .unorderedList:
            return AttributeContainer()
                .font(.system(size: UIFont.labelFontSize - 1))
                .foregroundColor(.primaryText)
                .lineHeight(.multiple(factor: 1.4))
                .paragraphStyle(Self.paragraphStyle())
        case .codeBlock:
            return AttributeContainer()
                .font(
                    .system(
                        size: UIFont.systemFontSize-1,
                        design: .monospaced
                    )
                    .width(.compressed)
                    .leading(.tight)
                )
                .foregroundColor(.white)
                .backgroundColor(.secondaryText)
        case .blockQuote:
            return AttributeContainer()
                .font(
                    Typography.system.callout.italic()
                )
                .foregroundColor(.secondaryText)
                .paragraphStyle(Self.paragraphStyle())
        case .paragraph:
            return base
        case .thematicBreak:
            return AttributeContainer()
                .lineHeight(.multiple(factor: 1))
                .foregroundColor(.tertiaryText)
        default:
            return base
        }
    }
}

extension GitHubMarkdownStyle {
    var blockSpacing: AttributeContainer {
        block(.paragraph).paragraphStyle(
            Self.paragraphStyle(paragraphSpacing: 6)
        )
    }

    var blockquote: AttributeContainer {
        block(.blockQuote).paragraphStyle(
            Self.paragraphStyle(
                firstLineHeadIndent: 12,
                headIndent: 12,
                paragraphSpacing: 4
            )
        )
    }

    var divider: AttributeContainer {
        block(.thematicBreak).paragraphStyle(
            Self.paragraphStyle(paragraphSpacing: 6)
        )
    }

    var mention: AttributeContainer {
        AttributeContainer()
            .font(.system(.body, design: .serif).weight(.medium))
            .foregroundColor(.red)
    }

    var hashtag: AttributeContainer {
        AttributeContainer().foregroundColor(.blue)
    }

    func list(
        level: Int,
        markerWidth: CGFloat,
        ordered: Bool,
        ordinal: Int = 1
    ) -> AttributeContainer {
        let kind: PresentationIntent.Kind = ordered
            ? .listItem(ordinal: ordinal)
            : .unorderedList
        let baseIndent = CGFloat(max(level, 0)) * 12
        return block(kind).paragraphStyle(
            Self.paragraphStyle(
                firstLineHeadIndent: baseIndent,
                headIndent: baseIndent + markerWidth,
                paragraphSpacing: 2
            )
        )
    }

    private static func paragraphStyle(
        firstLineHeadIndent: CGFloat = 0,
        headIndent: CGFloat = 0,
        paragraphSpacing: CGFloat = 0
    ) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.lineBreakStrategy = .hangulWordPriority
        style.allowsDefaultTighteningForTruncation = false
        style.alignment = .natural
        style.lineSpacing = 1
        style.lineHeightMultiple = 1.4
        style.firstLineHeadIndent = firstLineHeadIndent
        style.headIndent = headIndent
        style.paragraphSpacing = paragraphSpacing
        return style.copy() as? NSParagraphStyle ?? style
    }
}

extension AttributeContainer {
    static var markdownParagraph: AttributeContainer {
        AttributeContainer()
            .font(Typography.system.body)
            .paragraphStyle(GitHubMarkdownStyle.defaultParagraphStyle)
    }
}

private extension GitHubMarkdownStyle {
    static var defaultParagraphStyle: NSParagraphStyle {
        paragraphStyle()
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
