//  String+Extensions.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)

    import UIKit

#elseif os(OSX)

    import Cocoa

#endif

public extension String {
    /// Trim
    var trim: String {
        trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    /// Remove extra white spaces
    var extendedTrim: String {
        let components = components(separatedBy: CharacterSet.whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ").trim
    }

    /// Decode HTML entities
    var decoded: String {
        guard let encodedData = data(using: String.Encoding.utf8) else { return self }

        let attributedOptions: [NSAttributedString.DocumentReadingOptionKey: Any] =
            [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)
            ]

        do {
            let attributedString = try NSAttributedString(
                data: encodedData,
                options: attributedOptions,
                documentAttributes: nil
            )

            return attributedString.string
        } catch _ {
            return self
        }
    }

    /// Strip tags
    var tagsStripped: String {
        deleteTagByPattern(Regex.rawTagPattern)
    }

    /// Delete tab by pattern
    func deleteTagByPattern(_ pattern: String) -> String {
        replacingOccurrences(of: pattern, with: "", options: .regularExpression, range: nil)
    }

    /// Substring
    func substring(_ start: Int, end: Int) -> String {
        substring(NSRange(location: start, length: end - start))
    }

    func substring(_ range: NSRange) -> String {
        var end = range.location + range.length
        end = end > count ? count - 1 : end

        return substring(range.location, end: end)
    }

    /// Check if url is an image
    func isImage() -> Bool {
        let possible = ["gif", "jpg", "jpeg", "png", "bmp"]
        if let url = URL(string: self),
           possible.contains(url.pathExtension) {
            return true
        }

        return false
    }

    func isOpenGraphImage() -> Bool {
        Regex.test(self, regex: Regex.openGraphImagePattern)
    }

    func isVideo() -> Bool {
        let possible = ["mp4", "mov", "mpeg", "avi", "m3u8"]
        if let url = URL(string: self),
           possible.contains(url.pathExtension) {
            return true
        }

        return false
    }

    /// Split into substring of equal length
    func split(by length: Int) -> [String] {
        var startIndex = startIndex
        var results = [Substring]()

        while startIndex < endIndex {
            let endIndex = index(startIndex, offsetBy: length, limitedBy: endIndex) ?? endIndex
            results.append(self[startIndex ..< endIndex])
            startIndex = endIndex
        }

        return results.map { String($0) }
    }
}
