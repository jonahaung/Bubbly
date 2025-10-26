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
			.multilineTextAlignment(.leading)
			.allowsTightening(true)
			.equatable(by: text)
			.fixedSize(horizontal: false, vertical: true)
    }
}
