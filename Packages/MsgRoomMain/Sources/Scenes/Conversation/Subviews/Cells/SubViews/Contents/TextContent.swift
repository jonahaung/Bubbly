//
//  TextContent.swift
//  Conversation
//
//  Created by Aung Ko Min on 31/1/22.
//

import SwiftUI
import XUI

struct TextContent: View {
    let text: String
    var body: some View {
		Text(.init(text))
    }
}

struct MarkdownTextContent: View {
	let text: AttributedString
	var body: some View {
		Text(text)
	}
}
