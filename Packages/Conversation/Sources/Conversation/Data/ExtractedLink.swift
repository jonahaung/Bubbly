//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

struct ExtractedLink: Hashable, Identifiable {
	let url: URL
	let range: Range<String.Index>
	let matchedText: String

	var id: String {
		matchedText
	}

	var host: String {
		url.host() ?? "unknown"
	}
}

enum LinkExtractor {

	// MARK: Internal

	static func extractLinks(from text: String) -> [ExtractedLink] {
		guard let regularExpression = try? NSRegularExpression(pattern: pattern, options: [])
		else {
			return []
		}
		let nsString = text as NSString
		let matches = regularExpression.matches(
			in: text,
			options: [],
			range: NSRange(location: 0, length: nsString.length),
		)

		var seen = Set<URL>()
		var links = [ExtractedLink]()
		links.reserveCapacity(matches.count)

		for match in matches {
			guard let range = Range(match.range(at: 1), in: text) else {
				continue
			}

			var rawString = String(text[range])
			rawString = trimTrailingPunctuation(rawString)

			// If no scheme, assume https
			let normalized: String =
				if rawString.lowercased().hasPrefix("http://") || rawString
					.lowercased()
					.hasPrefix("https://")
				{
					rawString
				} else {
					"https://" + rawString
				}

			guard let url = URL(string: normalized) else {
				continue
			}

			// De-dupe (optional)
			guard seen.insert(url).inserted else {
				continue
			}

			links.append(.init(url: url, range: range, matchedText: rawString))
		}

		return links
	}

	static func extractURLs(from text: String) -> [URL] {
		extractLinks(from: text).map(\.url)
	}

	// MARK: Private

	/// Matches:
	/// 1) http(s)://...
	/// 2) www.example.com/...
	/// 3) example.com/... (with a TLD)
	///
	/// Note: This is pragmatic, not “perfect URL spec”.
	private static let pattern =
		#"""
		(?xi)
		\b(
		 https?://[^\s<>()"\]]+
		 |
		 (?:www\.)[a-z0-9-]+(?:\.[a-z0-9-]+)+(?:/[^\s<>()"\]]*)?
		 |
		 [a-z0-9-]+(?:\.[a-z0-9-]+)+\b(?:/[^\s<>()"\]]*)?
		)
		"""#

	private static func trimTrailingPunctuation(_ string: String) -> String {
		var result = string
		while let last = result.unicodeScalars.last,
		      CharacterSet(charactersIn: ".,;:!?)\u{201D}\u{2019}").contains(last)
		{
			result.removeLast()
		}
		return result
	}
}
