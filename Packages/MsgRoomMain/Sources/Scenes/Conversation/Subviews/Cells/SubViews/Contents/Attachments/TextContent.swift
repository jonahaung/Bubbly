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
			.font(.chat.message)
			.lineSpacing(3)
			.equatable(by: text)
	}
}
