//  MarkdownFormatter.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Contacts
import SwiftUI

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
            return markdown.mergingAttributes(style.block(.paragraph))
        }
        return AttributedString(string, attributes: style.block(.paragraph))
    }

    public func richText(
        for string: String
    ) -> AttributedString {
        guard string.containsMarkdown else {
            return .init(string, attributes: style.base)
        }
        let blocks = MarkdownParser.parse(string)

        var result = AttributedString()

        for block in blocks {
            appendSpacingIfNeeded(&result)

            switch block {
            case .heading(let level, let text):
                result += renderHeading(level: level, text: text, style: style)
            case .paragraph(let text):
                result += parseInline(text, base: style.base)
            case .codeBlock(let lang, let content):
                result += renderCodeBlock(
                    lang: lang,
                    content: content,
                    style: style
                )
            case .listItem(let level, let text):
                result += renderUnorderedListItem(
                    level: level,
                    text: text,
                    style: style
                )
            case .orderedListItem(let level, let index, let text):
                result += renderOrderedListItem(
                    level: level,
                    index: index,
                    text: text,
                    style: style
                )
            case .blockquote(let text):
                result += renderBlockquote(text: text, style: style)
            case .horizontalRule:
                result += renderDivider(style: style)
            case .mention(let username):
                var attr = style.base
                attr.font = .system(.body, design: .serif).weight(.medium)
                attr.foregroundColor = .red
                result += AttributedString("@\(username)", attributes: attr)
            case .hashtag(let topic):
                var attr = style.base
                attr.foregroundColor = .blue
                result += AttributedString("#\(topic)", attributes: attr)
            case .unknown(let text):
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
        var spacerAttributes = self.style.block(.paragraph)
        let paragraph = NSMutableParagraphStyle()
        paragraph.paragraphSpacing = 6
        spacerAttributes.paragraphStyle = paragraph
        attr += AttributedString("\n", attributes: spacerAttributes)
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
        let base = style.block(.blockQuote)
        let paragraph = NSMutableParagraphStyle()
        paragraph.firstLineHeadIndent = 12
        paragraph.headIndent = 12
        paragraph.paragraphSpacing = 4
        var attributes = base
        attributes.paragraphStyle = paragraph
        let lines = text.split(
            separator: "\n",
            omittingEmptySubsequences: false
        )
        var result = AttributedString()
        for (i, line) in lines.enumerated() {
            result += parseInline(String(line), base: attributes)
            if i < lines.count - 1 { result += "\n" }
        }
        return result
    }

    // MARK: Dividers

    func renderDivider(style: GitHubMarkdownStyle) -> AttributedString {
        var attributes = style.block(.paragraph)
        attributes.foregroundColor = .secondary
        let paragraph = NSMutableParagraphStyle()
        paragraph.paragraphSpacing = 6
        attributes.paragraphStyle = paragraph
        return AttributedString("–––––––", attributes: attributes)
    }

    // MARK: Unordered List Items

    func renderUnorderedListItem(
        level: Int,
        text: String,
        style: GitHubMarkdownStyle
    ) -> AttributedString {
        var attributes = style.block(.unorderedList)
        let indentPerLevel: CGFloat = 12
        let bulletWidth: CGFloat = 14
        let baseIndent = CGFloat(level) * indentPerLevel
        let paragraph = NSMutableParagraphStyle()
        paragraph.firstLineHeadIndent = baseIndent
        paragraph.headIndent = baseIndent + bulletWidth
        paragraph.paragraphSpacing = 2
        attributes.paragraphStyle = paragraph
        let bullets = ["-", "•", "‣", "◦"]
        let bullet = bullets[level % bullets.count]
        let bulletAttr = AttributedString("\(bullet) ", attributes: attributes)
        return bulletAttr + parseInline(text, base: attributes)
    }

    // MARK: Ordered List Items

    func renderOrderedListItem(
        level: Int,
        index: Int,
        text: String,
        style: GitHubMarkdownStyle
    ) -> AttributedString {
        var attributes = style.block(.listItem(ordinal: index))
        let indentPerLevel: CGFloat = 12
        let numberString = "\(index). "
        let numberWidth: CGFloat = 18
        let baseIndent = CGFloat(level) * indentPerLevel
        let paragraph = NSMutableParagraphStyle()
        paragraph.firstLineHeadIndent = baseIndent
        paragraph.headIndent = baseIndent + numberWidth
        paragraph.paragraphSpacing = 2
        attributes.paragraphStyle = paragraph
        let numberAttr = AttributedString(numberString, attributes: attributes)
        return numberAttr + parseInline(text, base: attributes)
    }
}
