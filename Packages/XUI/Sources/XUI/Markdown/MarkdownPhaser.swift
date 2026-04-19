//
//  Created by Aung Ko Min on 10/4/26.
//

import Foundation

// MARK: - Markdown Parser

public enum MarkdownParser {
    // MARK: Public
    public static func parse(_ markdown: String) -> [MarkdownItem] {
        var elements = [MarkdownItem]()
        let lines = markdown.split(
            separator: "\n",
            omittingEmptySubsequences: false
        )

        var inCodeBlock = false
        var codeBlockContent = ""
        var codeBlockLanguage: String?
        var blockquoteBuffer = [String]()

        for line in lines {
            let rawLine = String(line)
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    elements.append(
                        .codeBlock(
                            language: codeBlockLanguage,
                            content: codeBlockContent.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ),
                        )
                    )
                    codeBlockContent = ""
                    codeBlockLanguage = nil
                } else {
                    // Start code block
                    codeBlockLanguage = String(trimmed.dropFirst(3))
                        .trimmingCharacters(in: .whitespaces)
                }
                inCodeBlock.toggle()
                continue
            }

            if inCodeBlock {
                codeBlockContent += rawLine + "\n"
                continue
            }

            if trimmed.hasPrefix(">") {
                blockquoteBuffer.append(
                    trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                )
                continue
            } else if !blockquoteBuffer.isEmpty {
                // Flush blockquote buffer
                let combined = blockquoteBuffer.joined(separator: "\n")
                elements.append(.blockquote(text: combined))
                blockquoteBuffer.removeAll()
            }

            // Horizontal rule
            if trimmed == "---" || trimmed == "***" {
                elements.append(.horizontalRule)
                continue
            }

            // Heading detection
            if trimmed.hasPrefix("#") {
                let level = trimmed.prefix { $0 == "#" }.count
                let text = trimmed.dropFirst(level).trimmingCharacters(
                    in: .whitespaces
                )
                elements.append(.heading(level: level, text: text))
                continue
            }

            // Ordered list
            if let match = orderedListItemRegex.firstMatch(
                in: rawLine,
                range: NSRange(location: 0, length: rawLine.utf16.count),
            ) {
                let nsLine = rawLine as NSString
                let indent = nsLine.substring(with: match.range(at: 1))
                let index = Int(nsLine.substring(with: match.range(at: 2))) ?? 0
                let text = nsLine.substring(with: match.range(at: 3))
                elements.append(
                    .orderedListItem(
                        level: indent.count / 2,
                        index: index,
                        text: text
                    )
                )
                continue
            }

            // Unordered list
            if let match = unorderedListItemRegex.firstMatch(
                in: rawLine,
                range: NSRange(location: 0, length: rawLine.utf16.count),
            ) {
                let nsLine = rawLine as NSString
                let indent = nsLine.substring(with: match.range(at: 1))
                let text = nsLine.substring(with: match.range(at: 2))
                elements.append(.listItem(level: indent.count / 2, text: text))
                continue
            }

            // Inline mentions/hashtags
            let inlineElements = parseInline(rawLine)
            elements.append(contentsOf: inlineElements)
        }

        // Flush any remaining blockquote
        if !blockquoteBuffer.isEmpty {
            let combined = blockquoteBuffer.joined(separator: "\n")
            elements.append(.blockquote(text: combined))
        }

        // Flush remaining code block
        if inCodeBlock, !codeBlockContent.isEmpty {
            elements.append(
                .codeBlock(
                    language: codeBlockLanguage,
                    content: codeBlockContent.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                )
            )
        }

        return elements
    }

    private static let orderedListItemRegex: NSRegularExpression =
        try! NSRegularExpression(pattern: "^(\\s*)(\\d+)\\.\\s+(.+)$")

    private static let unorderedListItemRegex: NSRegularExpression =
        try! NSRegularExpression(pattern: "^(\\s*)[-*]\\s+(.+)$")

    private static let mentionHashtagRegex: NSRegularExpression =
        try! NSRegularExpression(pattern: "(@\\w+|#\\w+)")

    private static func parseInline(_ text: String) -> [MarkdownItem] {
        var result = [MarkdownItem]()
        let nsText = text as NSString
        let matches = mentionHashtagRegex.matches(
            in: text,
            range: NSRange(location: 0, length: nsText.length),
        )
        var lastIndex = 0

        for match in matches {
            let range = match.range
            if range.location > lastIndex {
                let substring = nsText.substring(
                    with: NSRange(
                        location: lastIndex,
                        length: range.location - lastIndex,
                    )
                )
                if !substring.trimmingCharacters(in: .whitespaces).isEmpty {
                    result.append(.paragraph(text: substring))
                }
            }
            let token = nsText.substring(with: range)
            if token.hasPrefix("@") {
                result.append(.mention(username: String(token.dropFirst())))
            } else if token.hasPrefix("#") {
                result.append(.hashtag(topic: String(token.dropFirst())))
            }
            lastIndex = range.location + range.length
        }

        if lastIndex < nsText.length {
            let substring = nsText.substring(from: lastIndex)
            if !substring.trimmingCharacters(in: .whitespaces).isEmpty {
                result.append(.paragraph(text: substring))
            }
        }

        if result.isEmpty {
            result.append(.paragraph(text: text))
        }

        return result
    }
}
