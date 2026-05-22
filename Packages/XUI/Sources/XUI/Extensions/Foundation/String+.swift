//  String+.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

public extension String {
    /// Returns a copy of the string with all underscores replaced by spaces.
    var removingUnderscores: String {
        replace("_", with: " ")
    }

    func replace(_ target: String, with string: String) -> String {
        replacingOccurrences(of: target, with: string)
    }

    mutating func replacing(_ target: String, with string: String) {
        self = replacingOccurrences(of: target, with: string)
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
    var isWhitespace: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var notEmpty: Bool {
        !isWhitespace
    }

    func nsRange(from range: Range<String.Index>) -> NSRange {
        NSRange(range, in: self)
    }

    var language: String {
        NSLinguisticTagger.dominantLanguage(for: self) ?? ""
    }

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
    public var id: String {
        self
    }
}
