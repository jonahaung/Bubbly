//
//  ExtractedLink 2.swift
//  Conversation
//
//  Created by Aung Ko Min on 22/5/26.
//

import Foundation

public struct ExtractedLink: Hashable, Identifiable, Sendable {
    public let url: URL
    public let range: Range<String.Index>
    public let matchedText: String

    public var id: String {
        "\(url.absoluteString)-\(range.lowerBound.utf16Offset(in: matchedText))"
    }

    public var host: String {
        url.host(percentEncoded: false) ?? "unknown"
    }

    public init(url: URL, range: Range<String.Index>, matchedText: String) {
        self.url = url
        self.range = range
        self.matchedText = matchedText
    }
}

public enum LinkExtractor {

    public static func extractLinks(from text: String) -> [ExtractedLink] {
        guard let regex = regex else { return [] }

        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: nsRange)

        var seen = Set<String>()
        var links = [ExtractedLink]()
        links.reserveCapacity(matches.count)

        for match in matches {
            guard let originalRange = Range(match.range(at: 1), in: text) else { continue }

            let original = String(text[originalRange])
            let trimmed = original.trimmedLinkText

            guard !trimmed.isEmpty else { continue }

            let normalized = trimmed.hasHTTPPrefix ? trimmed : "https://\(trimmed)"
            guard
                let url = URL(string: normalized),
                let scheme = url.scheme?.lowercased(),
                scheme == "http" || scheme == "https",
                url.host(percentEncoded: false) != nil
            else { continue }

            guard seen.insert(url.absoluteString).inserted else { continue }

            let trimmedRange = originalRange.lowerBound..<text.index(
                originalRange.lowerBound,
                offsetBy: trimmed.count
            )

            links.append(
                ExtractedLink(
                    url: url,
                    range: trimmedRange,
                    matchedText: trimmed
                )
            )
        }

        return links
    }

    public static func extractURLs(from text: String) -> [URL] {
        extractLinks(from: text).map(\.url)
    }

    private static let regex = try? NSRegularExpression(
        pattern: pattern,
        options: []
    )

    private static let pattern = #"""
    (?xi)
    \b(
      https?://[^\s<>()"\]]+
      |
      (?:www\.)[a-z0-9-]+(?:\.[a-z0-9-]+)+(?:/[^\s<>()"\]]*)?
      |
      [a-z0-9-]+(?:\.[a-z0-9-]+)+\b(?:/[^\s<>()"\]]*)?
    )
    """#
}

private extension String {
    var hasHTTPPrefix: Bool {
        lowercased().hasPrefix("http://") || lowercased().hasPrefix("https://")
    }

    var trimmedLinkText: String {
        var result = self
        let trailing = CharacterSet(charactersIn: ".,;:!?)\u{201D}\u{2019}")

        while let last = result.unicodeScalars.last, trailing.contains(last) {
            result.removeLast()
        }

        return result
    }
}
