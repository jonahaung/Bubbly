//  InputText.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database

// MARK: - InputTextDelegate

@MainActor
protocol InputTextDelegate: AnyObject {
    func inputText(_ inputText: InputText, didBeganEditing text: String)
    func inputText(_ inputText: InputText, didEndEditing text: String)
    func inputText(_ inputText: InputText, didInsert text: String)
    func inputText(_ inputText: InputText, didInsertLinks links: [ExtractedLink])
}

@MainActor
@Observable
final class InputText {
    private(set)
    var text: String = .init()
    var selection: TextSelection?

    func set(text: String) {
        handleTextChange(previous: self.text, current: text)
    }

    func append(_ string: String) {
        guard string.isEmpty == false else {
            return
        }
        text += string
    }

    var hasText: Bool {
        !text.string.isWhitespace
    }

    @ObservationIgnored weak var delegate: InputTextDelegate?
    @ObservationIgnored private let linkWorker: LinkExtractorWorker = .init()
    @ObservationIgnored private var linkExtractionTask: Task<Void, Never>?

    func clear() {
        linkExtractionTask?.cancel()
        selection = nil
        text = .init()
    }

    private func handleTextChange(previous: String, current: String) {
        guard previous != current else {
            return
        }
        self.text = current
        if previous.count == 0 && current.count > 0 {
            delegate?.inputText(self, didBeganEditing: current)
        }
        if previous.count > 0 && current.count == 0 {
            delegate?.inputText(self, didEndEditing: current)
        }
        
        if (current.count - previous.count) > 1  {
            let inserted = current.replace(previous, with: String())
            delegate?.inputText(self, didInsert: inserted)
            parseLinks(inserted)
        }
    }

    private func parseLinks(_ string: String) {
        linkExtractionTask?.cancel()
        let trimmed = string.trimmed
        guard trimmed.isWhitespace == false else {
            return
        }
        linkExtractionTask = Task { [weak self, linkWorker] in
            guard trimmed.mightContainLink else {
                return
            }
            let links = await linkWorker.extractLinks(from: string)
            guard Task.isCancelled == false, let self else {
                return
            }
            self.delegate?.inputText(self, didInsertLinks: links)
        }
    }
}

// MARK: - LinkExtractorWorker

private actor LinkExtractorWorker {
    func extractLinks(from text: String) -> [ExtractedLink] {
        LinkExtractor.extractLinks(from: text)
    }
}

private enum MarkdownAttributeApplier {
    static func apply(to attributedText: inout AttributedString, source: String) {
        applyInlineCode(to: &attributedText, source: source)
        applyStrong(to: &attributedText, source: source)
        applyEmphasis(to: &attributedText, source: source)
        applyStrikethrough(to: &attributedText, source: source)
    }

    private static func applyInlineCode(to attributedText: inout AttributedString, source: String) {
        for range in ranges(
            pattern: #"`([^`\n]+)`"#,
            capture: 1,
            source: source,
            attributedText: attributedText
        ) {
            attributedText[range].inlinePresentationIntent = .code
            attributedText[range].font = .system(.body, design: .monospaced)
        }
    }

    private static func applyStrong(to attributedText: inout AttributedString, source: String) {
        for range in ranges(
            pattern: #"(\*\*|__)(?=\S)(.+?)(?<=\S)\1"#,
            capture: 2,
            source: source,
            attributedText: attributedText
        ) {
            attributedText[range].inlinePresentationIntent = .stronglyEmphasized
        }
    }

    private static func applyEmphasis(to attributedText: inout AttributedString, source: String) {
        for range in ranges(
            pattern: #"(?<!\*)\*(?!\*)(?=\S)(.+?)(?<=\S)\*(?!\*)"#,
            capture: 1,
            source: source,
            attributedText: attributedText
        ) {
            attributedText[range].inlinePresentationIntent = .emphasized
        }
        for range in ranges(
            pattern: #"(?<!\w)_(?=\S)(.+?)(?<=\S)_(?!\w)"#,
            capture: 1,
            source: source,
            attributedText: attributedText
        ) {
            attributedText[range].inlinePresentationIntent = .emphasized
        }
    }

    private static func applyStrikethrough(to attributedText: inout AttributedString, source: String) {
        for range in ranges(
            pattern: #"~~(?=\S)(.+?)(?<=\S)~~"#,
            capture: 1,
            source: source,
            attributedText: attributedText
        ) {
            attributedText[range].inlinePresentationIntent = .strikethrough
        }
    }

    private static func ranges(
        pattern: String,
        capture: Int,
        source: String,
        attributedText: AttributedString
    ) -> [Range<AttributedString.Index>] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let matches = regex.matches(
            in: source,
            range: NSRange(source.startIndex ..< source.endIndex, in: source)
        )

        var ranges = [Range<AttributedString.Index>]()
        ranges.reserveCapacity(matches.count)

        for match in matches where match.numberOfRanges > capture {
            guard let stringRange = Range(match.range(at: capture), in: source),
                  let lowerBound = AttributedString.Index(stringRange.lowerBound, within: attributedText),
                  let upperBound = AttributedString.Index(stringRange.upperBound, within: attributedText) else {
                continue
            }
            ranges.append(lowerBound ..< upperBound)
        }
        return ranges
    }
}

public extension AttributedString {
    var string: String {
        .init(characters)
    }
}

private extension String {
    var mightContainLink: Bool {
        localizedCaseInsensitiveContains("://")
            || localizedCaseInsensitiveContains("www.")
            || range(of: #"\b[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+\b"#, options: .regularExpression) != nil
    }
}
