//  MarkdownParser.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

public enum MarkdownParser {
    public static func parse(_ markdown: String) -> [MarkdownItem] {
        var items = [MarkdownItem]()
        var codeBlockContent = [Substring]()
        var codeBlockLanguage: String?
        var blockquoteLines = [String]()
        var isInsideCodeBlock = false

        for line in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .newlines)

            if trimmed.hasPrefix("```") {
                if isInsideCodeBlock {
                    appendCodeBlock(
                        to: &items,
                        language: codeBlockLanguage,
                        lines: codeBlockContent
                    )
                    codeBlockContent.removeAll(keepingCapacity: true)
                    codeBlockLanguage = nil
                } else {
                    flushBlockquote(&blockquoteLines, into: &items)
                    codeBlockLanguage = String(trimmed.dropFirst(3))
                        .trimmingCharacters(in: .whitespaces)
                        .nilIfEmpty
                }
                isInsideCodeBlock.toggle()
                continue
            }

            if isInsideCodeBlock {
                codeBlockContent.append(line)
                continue
            }

            if trimmed.hasPrefix(">") {
                blockquoteLines.append(
                    trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                )
                continue
            }

            flushBlockquote(&blockquoteLines, into: &items)

            if isHorizontalRule(trimmed) {
                items.append(.horizontalRule)
            } else if let heading = heading(from: trimmed) {
                items.append(heading)
            } else if let orderedListItem = orderedListItem(from: line) {
                items.append(orderedListItem)
            } else if let unorderedListItem = unorderedListItem(from: line) {
                items.append(unorderedListItem)
            } else {
                items.append(.paragraph(text: String(line)))
            }
        }

        flushBlockquote(&blockquoteLines, into: &items)
        if isInsideCodeBlock {
            appendCodeBlock(
                to: &items,
                language: codeBlockLanguage,
                lines: codeBlockContent
            )
        }
        return items
    }

    static func requiresRichTextParsing(_ text: String) -> Bool {
        containsMarkdownSyntax(text) || text.contains("@") || text.contains("#")
    }

    static func containsMarkdownSyntax(_ text: String) -> Bool {
        guard text.contains(where: { "*_`[]>#!-".contains($0) }) else {
            return text.split(separator: "\n", omittingEmptySubsequences: false)
                .contains { orderedListItem(from: $0) != nil }
        }

        if hasPairedDelimiter("*", in: text)
            || hasPairedDelimiter("_", in: text)
            || text.contains("`")
            || text.contains("](") || text.contains("![") {
            return true
        }

        return text.split(separator: "\n", omittingEmptySubsequences: false)
            .contains { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return heading(from: trimmed) != nil
                    || trimmed.hasPrefix(">")
                    || isHorizontalRule(trimmed)
                    || orderedListItem(from: line) != nil
                    || unorderedListItem(from: line) != nil
            }
    }
}

extension MarkdownParser {
    private static func heading(from line: String) -> MarkdownItem? {
        let level = line.prefix(while: { $0 == "#" }).count
        guard (1 ... 6).contains(level) else { return nil }

        let content = line.dropFirst(level)
        guard content.isEmpty || content.first?.isWhitespace == true else {
            return nil
        }
        return .heading(
            level: level,
            text: content.trimmingCharacters(in: .whitespaces)
        )
    }

    private static func hasPairedDelimiter(
        _ delimiter: Character,
        in text: String
    ) -> Bool {
        guard let first = text.firstIndex(of: delimiter) else { return false }
        return text[text.index(after: first)...].contains(delimiter)
    }

    private static func orderedListItem(from line: Substring) -> MarkdownItem? {
        let indentation = line.prefix(while: { $0.isWhitespace })
        let content = line.dropFirst(indentation.count)
        let digits = content.prefix(while: { $0.isNumber })
        guard !digits.isEmpty,
              let periodIndex = content.index(
                  content.startIndex,
                  offsetBy: digits.count,
                  limitedBy: content.endIndex
              ),
              periodIndex < content.endIndex,
              content[periodIndex] == ".",
              let spacingIndex = content.index(
                  periodIndex,
                  offsetBy: 1,
                  limitedBy: content.endIndex
              ),
              spacingIndex < content.endIndex,
              content[spacingIndex].isWhitespace,
              let index = Int(digits) else {
            return nil
        }

        let text = content[spacingIndex...]
            .drop(while: { $0.isWhitespace })
        guard !text.isEmpty else { return nil }
        return .orderedListItem(
            level: indentationLevel(for: indentation),
            index: index,
            text: String(text)
        )
    }

    private static func unorderedListItem(from line: Substring) -> MarkdownItem? {
        let indentation = line.prefix(while: { $0.isWhitespace })
        let content = line.dropFirst(indentation.count)
        guard let marker = content.first,
              marker == "-" || marker == "*",
              content.count > 1 else {
            return nil
        }

        let spacingIndex = content.index(after: content.startIndex)
        guard content[spacingIndex].isWhitespace else { return nil }
        let text = content[spacingIndex...].drop(while: { $0.isWhitespace })
        guard !text.isEmpty else { return nil }
        return .listItem(
            level: indentationLevel(for: indentation),
            text: String(text)
        )
    }

    private static func indentationLevel(for indentation: Substring) -> Int {
        indentation.reduce(into: 0) { columns, character in
            columns += character == "\t" ? 2 : 1
        } / 2
    }

    private static func isHorizontalRule(_ line: String) -> Bool {
        let compact = line.filter { !$0.isWhitespace }
        guard compact.count >= 3, let marker = compact.first,
              marker == "-" || marker == "*" || marker == "_" else {
            return false
        }
        return compact.allSatisfy { $0 == marker }
    }

    private static func flushBlockquote(
        _ lines: inout [String],
        into items: inout [MarkdownItem]
    ) {
        guard !lines.isEmpty else { return }
        items.append(.blockquote(text: lines.joined(separator: "\n")))
        lines.removeAll(keepingCapacity: true)
    }

    private static func appendCodeBlock(
        to items: inout [MarkdownItem],
        language: String?,
        lines: [Substring]
    ) {
        items.append(
            .codeBlock(
                language: language,
                content: lines.joined(separator: "\n")
            )
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
