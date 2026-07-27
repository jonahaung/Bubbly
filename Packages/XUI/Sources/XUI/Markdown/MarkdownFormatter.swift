//  MarkdownFormatter.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public struct MarkdownFormatter: Sendable {
    private let style: GitHubMarkdownStyle

    public init(style: GitHubMarkdownStyle = .init()) {
        self.style = style
    }

    public func markdownText(for string: String) -> AttributedString {
        parseMarkdown(string, base: style.block(.paragraph))
    }

    @available(*, deprecated, renamed: "markdownText(for:)")
    public func markDownText(for string: String) -> AttributedString {
        markdownText(for: string)
    }

    public func richText(for string: String) -> AttributedString {
        guard MarkdownParser.requiresRichTextParsing(string) else {
            return AttributedString(string, attributes: style.base)
        }

        return MarkdownParser.parse(string).reduce(into: AttributedString()) {
            result,
                item in
            appendBlockSpacing(to: &result)
            result += render(item)
        }
    }
}

extension MarkdownFormatter {
    func parseInline(
        _ text: String,
        base: AttributeContainer
    ) -> AttributedString {
        var result = parseMarkdown(text, base: base)
        applyInlineTokenStyles(to: &result)
        return result
    }

    private func parseMarkdown(
        _ text: String,
        base: AttributeContainer
    ) -> AttributedString {
        guard
              let result = try? AttributedString(
                  markdown: text,
                  options: .init(
                      allowsExtendedAttributes: true,
                      interpretedSyntax: .full,
                      failurePolicy: .returnPartiallyParsedIfPossible
                  )
              ) else {
            return AttributedString(text, attributes: base)
        }

        return result.mergingAttributes(base)
    }

    private func render(_ item: MarkdownItem) -> AttributedString {
        switch item {
        case let .heading(level, text):
            parseInline(text, base: style.block(.header(level: level)))
        case let .paragraph(text):
            parseInline(text, base: style.base)
        case let .codeBlock(language, content):
            AttributedString(
                " \n\(content.lines().map{ " \($0)"}.joined(separator: "\n"))\n\n",
                attributes: style.block(.codeBlock(languageHint: language))
            )
        case let .listItem(level, text):
            renderUnorderedListItem(level: level, text: text)
        case let .orderedListItem(level, index, text):
            renderOrderedListItem(level: level, index: index, text: text)
        case let .blockquote(text):
            renderBlockquote(text)
        case .horizontalRule:
            AttributedString("–––––––", attributes: style.divider)
        case let .mention(username):
            parseInline("@\(username)", base: style.base)
        case let .hashtag(topic):
            parseInline("#\(topic)", base: style.base)
        case let .unknown(text):
            parseInline(text, base: style.base)
        }
    }

    private func appendBlockSpacing(to result: inout AttributedString) {
        guard !result.characters.isEmpty, result.characters.last != "\n" else {
            return
        }
        result += AttributedString("\n", attributes: style.blockSpacing)
    }

    private func renderBlockquote(_ text: String) -> AttributedString {
        let attributes = style.blockquote
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)

        return lines.enumerated().reduce(into: AttributedString()) {
            result,
                element in
            result += parseInline(String(element.element), base: attributes)
            if element.offset < lines.count - 1 {
                result += AttributedString("\n", attributes: attributes)
            }
        }
    }

    private func renderUnorderedListItem(
        level: Int,
        text: String
    ) -> AttributedString {
        let attributes = style.list(level: level, markerWidth: 14, ordered: false)
        let marker = String(repeating: "  ", count: level) + "• "
        return AttributedString(marker, attributes: attributes)
            + parseInline(text, base: attributes)
    }

    private func renderOrderedListItem(
        level: Int,
        index: Int,
        text: String
    ) -> AttributedString {
        let marker = "\(index). "
        let markerWidth = max(18, CGFloat(marker.count) * 7)
        let attributes = style.list(
            level: level,
            markerWidth: markerWidth,
            ordered: true,
            ordinal: index
        )
        return AttributedString(marker, attributes: attributes)
            + parseInline(text, base: attributes)
    }

    private func applyInlineTokenStyles(to result: inout AttributedString) {
        var index = result.startIndex

        while index < result.endIndex {
            let character = result.characters[index]
            guard character == "@" || character == "#" else {
                index = result.characters.index(after: index)
                continue
            }

            let tokenStart = index
            var tokenEnd = result.characters.index(after: index)
            let wordStart = tokenEnd

            while tokenEnd < result.endIndex,
                  result.characters[tokenEnd].isMarkdownTokenCharacter {
                tokenEnd = result.characters.index(after: tokenEnd)
            }

            guard tokenEnd > wordStart else {
                index = tokenEnd
                continue
            }

            let attributes = character == "@" ? style.mention : style.hashtag
            result[tokenStart ..< tokenEnd].mergeAttributes(attributes)
            index = tokenEnd
        }
    }
}

private extension Character {
    var isMarkdownTokenCharacter: Bool {
        isLetter || isNumber || self == "_"
    }
}
