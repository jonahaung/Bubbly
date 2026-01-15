//
//  String+.swift
//
//
//  Created by Aung Ko Min on 10/6/23.
//

import SwiftUI

public extension String {
	var remove_: String {
		replace("_", with: " ")
	}

	func replace(_ target: String, with string: String) -> String {
		replacingOccurrences(of: target, with: string)
	}

	func removing(_ substring: String) -> String {
		replacingOccurrences(of: substring, with: "")
	}

	var trimmed: String {
		trimmingCharacters(in: .whitespacesAndNewlines)
	}

	var withoutSpacesAndNewLines: String {
		trimmed.replace(" ", with: "")
	}

	func toCurrencyFormat() -> String {
		if let intValue = Int(self) {
			let numberFormatter = NumberFormatter()
			numberFormatter.locale = .current
			numberFormatter.numberStyle = .currency
			return numberFormatter.string(from: NSNumber(value: intValue)) ?? ""
		}
		return ""
	}

	var isWhitespace: Bool {
		trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	var notEmpty: Bool { !isWhitespace }

	func nsRange(from range: Range<String.Index>) -> NSRange {
		NSRange(range, in: self)
	}

	var language: String { NSLinguisticTagger.dominantLanguage(for: self) ?? "" }

	var nonLineBreak: String {
		replacingOccurrences(of: " ", with: "\u{00a0}")
	}

	func contains(_ string: String, caseSensitive: Bool = true) -> Bool {
		if !caseSensitive {
			return range(of: string, options: .caseInsensitive) != nil
		}
		return range(of: string) != nil
	}

	func lines() -> [String] {
		var result = [String]()
		enumerateLines { line, _ in
			result.append(line)
		}
		return result
	}

	func words() -> [String] {
		let comps = components(separatedBy: CharacterSet.whitespacesAndNewlines)
		return comps.filter { !$0.isWhitespace }
	}

	func nsRange() -> NSRange {
		NSRange(startIndex ..< endIndex, in: self)
	}

	var localizedKey: LocalizedStringKey {
		.init(self)
	}

	var stringsBesideColon: (String?, String) {
		let strings = split(separator: ":").map(String.init)
		if strings.count == 2, strings[0].notEmpty {
			return (strings[0], strings[1])
		}
		return (nil, self)
	}

	var firstLetterCapitalized: String {
		prefix(1).capitalized + dropFirst()
	}
}

extension String: @retroactive Identifiable {
	public var id: String { self }
}
