//
//  LinkExtractor.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 12/12/25.
//

import Foundation

struct ExtractedLink: Hashable, Identifiable {
	var id: Range<String.Index> { range }
	let url: URL
	let range: Range<String.Index>
	let matchedText: String
	var host: String {
		url.host() ?? "unknown"
	}
}

enum LinkExtractor {

	// Matches:
	// 1) http(s)://...
	// 2) www.example.com/...
	// 3) example.com/... (with a TLD)
	//
	// Note: This is pragmatic, not “perfect URL spec”.
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

	static func extractLinks(from text: String) -> [ExtractedLink] {
		guard let re = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
		let ns = text as NSString
		let matches = re.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))

		var seen = Set<URL>()
		var out: [ExtractedLink] = []
		out.reserveCapacity(matches.count)

		for m in matches {
			guard let r = Range(m.range(at: 1), in: text) else { continue }

			var raw = String(text[r])
			raw = trimTrailingPunctuation(raw)

			// If no scheme, assume https
			let normalized: String
			if raw.lowercased().hasPrefix("http://") || raw.lowercased().hasPrefix("https://") {
				normalized = raw
			} else {
				normalized = "https://" + raw
			}

			guard let url = URL(string: normalized) else { continue }

			// De-dupe (optional)
			guard seen.insert(url).inserted else { continue }

			out.append(.init(url: url, range: r, matchedText: raw))
		}

		return out
	}

	static func extractURLs(from text: String) -> [URL] {
		extractLinks(from: text).map(\.url)
	}

	private static func trimTrailingPunctuation(_ s: String) -> String {
		var result = s
		// Common punctuation people type after links in sentences.
		while let last = result.unicodeScalars.last,
			  CharacterSet(charactersIn: ".,;:!?)\u{201D}\u{2019}").contains(last) {
			result.removeLast()
		}
		return result
	}
}
