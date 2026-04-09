//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

// MARK: - Markdown Element Types

public enum MarkdownElement: Sendable, Hashable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(language: String?, content: String)
    case listItem(text: String)
    case orderedListItem(index: Int, text: String)
    case blockquote(text: String)
    case horizontalRule
    case mention(username: String) // New: Mention element
    case hashtag(topic: String) // New: Hashtag element
    case unknown(text: String)
}

// MARK: - Markdown Parser

public enum MarkdownParser {
    private static let orderedListItemRegex: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: "^(\\d+)\\.\\s+(.+)$")
        } catch {
            fatalError("Failed to compile ordered list item regex: \(error)")
        }
    }()

    private static let mentionRegex: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: "@(\\w+)") // Matches @username
        } catch {
            fatalError("Failed to compile mention regex: \(error)")
        }
    }()

    private static let hashtagRegex: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: "#(\\w+)") // Matches #topic
        } catch {
            fatalError("Failed to compile hashtag regex: \(error)")
        }
    }()

    public static func parse(_ markdown: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)

        var inCodeBlock = false
        var currentCodeBlock = ""
        var currentLanguage: String?

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.hasPrefix("```") {
                handleCodeBlock(
                    line: trimmedLine,
                    inCodeBlock: &inCodeBlock,
                    currentCodeBlock: &currentCodeBlock,
                    currentLanguage: &currentLanguage,
                    elements: &elements
                )
            } else if inCodeBlock {
                currentCodeBlock += line + "\n"
            } else {
                handleMarkdownLine(trimmedLine, elements: &elements)
            }
        }

        // Append any remaining code block
        if inCodeBlock, !currentCodeBlock.isEmpty {
            elements.append(.codeBlock(
                language: currentLanguage,
                content: currentCodeBlock.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }

        return elements
    }

    private static func handleCodeBlock(
        line: String,
        inCodeBlock: inout Bool,
        currentCodeBlock: inout String,
        currentLanguage: inout String?,
        elements: inout [MarkdownElement]
    ) {
        if inCodeBlock {
            elements.append(.codeBlock(
                language: currentLanguage,
                content: currentCodeBlock.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
            currentCodeBlock = ""
            currentLanguage = nil
        } else {
            currentLanguage = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
        }
        inCodeBlock.toggle()
    }

    private static func handleMarkdownLine(_ line: String, elements: inout [MarkdownElement]) {
        if line.hasPrefix("# ") || line.hasPrefix("##") {
            parseHeading(line, elements: &elements)
        } else if line.hasPrefix(">") {
            parseBlockquote(line, elements: &elements)
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            parseListItem(line, elements: &elements)
        } else if let orderedMatch = parseOrderedListItem(line) {
            elements.append(.orderedListItem(index: orderedMatch.0, text: orderedMatch.1))
        } else if line == "---" || line == "***" {
            elements.append(.horizontalRule)
        } else if !line.isEmpty {
            // Parse mentions and hashtags within the paragraph
            let parsedElements = parseInlineElements(line)
            if parsedElements.isEmpty {
                elements.append(.paragraph(text: line))
            } else {
                elements.append(contentsOf: parsedElements)
            }
        }
    }

    private static func parseHeading(_ line: String, elements: inout [MarkdownElement]) {
        let headingLevel = line.prefix { $0 == "#" }.count
        let headingText = line.dropFirst(headingLevel).trimmingCharacters(in: .whitespaces)
        elements.append(.heading(level: headingLevel, text: headingText))
    }

    private static func parseBlockquote(_ line: String, elements: inout [MarkdownElement]) {
        let blockquoteText = line.dropFirst().trimmingCharacters(in: .whitespaces)
        elements.append(.blockquote(text: blockquoteText))
    }

    private static func parseListItem(_ line: String, elements: inout [MarkdownElement]) {
        let listItemText = line.dropFirst(2).trimmingCharacters(in: .whitespaces)
        elements.append(.listItem(text: listItemText))
    }

    private static func parseOrderedListItem(_ line: String) -> (Int, String)? {
        let nsLine = line as NSString
        if let match = orderedListItemRegex.firstMatch(
            in: line,
            range: NSRange(location: 0, length: nsLine.length)
        ) {
            let number = Int(nsLine.substring(with: match.range(at: 1))) ?? 0
            let text = nsLine.substring(with: match.range(at: 2))
                .trimmingCharacters(in: .whitespaces)
            return (number, text)
        }
        return nil
    }
	private static func parseInlineElements(_ text: String) -> [MarkdownElement] {
		var result: [MarkdownElement] = []

		let pattern = #"(@\w+|#\w+)"#
		guard let regex = try? NSRegularExpression(pattern: pattern) else {
			return [.paragraph(text: text)]
		}

		let nsText = text as NSString
		let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

		var lastIndex = 0

		for match in matches {
			let range = match.range

			// Text before mention/hashtag
			if range.location > lastIndex {
				let substring = nsText.substring(
					with: NSRange(location: lastIndex, length: range.location - lastIndex)
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

		// Remaining text
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
