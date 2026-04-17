//
//  MarkdownItem.swift
//  XUI
//
//  Created by Aung Ko Min on 11/4/26.
//


import Foundation

public enum MarkdownItem: Sendable, Hashable, CaseNameReflectable {
	case heading(level: Int, text: String)
	case paragraph(text: String)
	case codeBlock(language: String?, content: String)
	case listItem(level: Int, text: String) // level indicates nested depth
	case orderedListItem(level: Int, index: Int, text: String)
	case blockquote(text: String)
	case horizontalRule
	case mention(username: String)
	case hashtag(topic: String)
	case unknown(text: String)
}
