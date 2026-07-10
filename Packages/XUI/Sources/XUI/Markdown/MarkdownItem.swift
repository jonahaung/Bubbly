//  MarkdownItem.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

public enum MarkdownItem: Sendable, Hashable, CaseNameReflectable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(language: String?, content: String)
    case listItem(level: Int, text: String)
    case orderedListItem(level: Int, index: Int, text: String)
    case blockquote(text: String)
    case horizontalRule
    case mention(username: String)
    case hashtag(topic: String)
    case unknown(text: String)
}
