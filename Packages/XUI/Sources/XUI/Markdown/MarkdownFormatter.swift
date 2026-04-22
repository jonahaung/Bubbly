//  MarkdownFormatter.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI
import Contacts

public struct MarkdownFormatter {

    private let style: GitHubMarkdownStyle = .init()
    public init() {}

    // MARK: Public
    public func markDownText(for string: String) -> AttributedString {
        guard string.containsMarkdown else {
            return .init(string, attributes: style.base)
        }
        if let markdown = try? AttributedString(
            markdown: string,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) {
            return markdown.mergingAttributes(.paragraph)
        }
        return AttributedString(string, attributes: .paragraph)
    }

    public func richText(
        for string: String,
        layoutDirection _: LayoutDirection = .leftToRight
    ) -> AttributedString {
        guard string.containsMarkdown else {
            return .init(string, attributes: style.base)
        }
        let blocks = MarkdownParser.parse(string)

        var result = AttributedString()

        for block in blocks {
            appendSpacingIfNeeded(&result)

            switch block {
            case let .heading(level, text):
                result += renderHeading(level: level, text: text, style: style)
            case let .paragraph(text):
                result += parseInline(text, base: style.base)
            case let .codeBlock(lang, content):
                result += renderCodeBlock(
                    lang: lang,
                    content: content,
                    style: style
                )
            case let .listItem(level, text):
                result += renderUnorderedListItem(
                    level: level,
                    text: text,
                    style: style
                )
            case let .orderedListItem(level, index, text):
                result += renderOrderedListItem(
                    level: level,
                    index: index,
                    text: text,
                    style: style
                )
            case let .blockquote(text):
                result += renderBlockquote(text: text, style: style)
            case .horizontalRule:
                result += renderDivider(style: style)
            case let .mention(username):
                var attr = style.base
                attr.font = .system(
                    size: UIFont.labelFontSize,
                    weight: .medium,
                    design: .serif
                )
                attr.foregroundColor = .red
                result += AttributedString("@\(username)", attributes: attr)
            case let .hashtag(topic):
                var attr = style.base
                attr.foregroundColor = .blue
                result += AttributedString("#\(topic)", attributes: attr)
            case let .unknown(text):
                result += parseInline(text, base: style.base)
            }
        }
        return result
    }
}

// MARK: - Helpers

extension MarkdownFormatter {
    // MARK: Inline Parsing

    func parseInline(_ text: String, base: AttributeContainer)
        -> AttributedString
    {
        if text.containsMarkdown {
            if let result = try? AttributedString(
                markdown: text,
                options: .init(
                    allowsExtendedAttributes: true,
                    interpretedSyntax: .full,
                    failurePolicy: .returnPartiallyParsedIfPossible
                )
            ) {
                return result.mergingAttributes(base)
            }
        }
        return .init(text, attributes: base)
    }

    // MARK: Block Spacing

    func appendSpacingIfNeeded(
        _ attr: inout AttributedString,
        tight _: Bool = true
    ) {
        guard !attr.characters.isEmpty, attr.characters.last != "\n" else {
            return
        }

        attr += "\n"
    }

    // MARK: Headings

    func renderHeading(level: Int, text: String, style: GitHubMarkdownStyle)
        -> AttributedString
    {
        .init(text, attributes: style.block(.header(level: level)))
    }

    // MARK: Code Blocks

    func renderCodeBlock(
        lang: String?,
        content: String,
        style: GitHubMarkdownStyle
    ) -> AttributedString {
        let attributes = style.block(.codeBlock(languageHint: lang))
        return .init(content, attributes: attributes)
    }

    // MARK: Blockquote

    func renderBlockquote(text: String, style: GitHubMarkdownStyle)
        -> AttributedString
    {
        let attributes = style.block(.blockQuote)
        let lines = text.split(
            separator: "\n",
            omittingEmptySubsequences: false
        )
        var result = AttributedString()
        for line in lines {
            result += AttributedString("│ ", attributes: attributes)
            result += parseInline(String(line), base: attributes)
        }
        return result
    }

    // MARK: Dividers

    func renderDivider(style: GitHubMarkdownStyle) -> AttributedString {
        var attributes = style.block(.paragraph)
        attributes.foregroundColor = .secondary
        return AttributedString("–––––––", attributes: attributes)
    }

    // MARK: Unordered List Items

    func renderUnorderedListItem(
        level: Int,
        text: String,
        style: GitHubMarkdownStyle
    ) -> AttributedString {
        let attributes = style.block(.unorderedList)
        let bullets = ["-", "•", "‣", "◦"]
        let bullet = bullets[level % bullets.count]
        let indent = String(repeating: " ", count: level)
        return AttributedString("\(indent)\(bullet) ", attributes: attributes)
            + parseInline(
                text,
                base: attributes
            )
    }

    // MARK: Ordered List Items

    func renderOrderedListItem(
        level: Int,
        index: Int,
        text: String,
        style: GitHubMarkdownStyle
    ) -> AttributedString {
        let attributes = style.block(.listItem(ordinal: level))

        let indent = String(repeating: " ", count: level)
        return AttributedString("\(indent)\(index). ", attributes: attributes)
            + parseInline(
                text,
                base: attributes
            )
    }
}
