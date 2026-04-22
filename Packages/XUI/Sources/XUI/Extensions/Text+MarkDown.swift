//  Text+MarkDown.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public extension Text {
    init(markdown text: String) {
        do {
            let attributedString = try AttributedString(markdown: text)
            self = .init(attributedString)
        } catch {
            self = .init(text)
        }
    }
}
