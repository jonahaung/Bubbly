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
		Text(text)
			.allowsTightening(true)
    }
}
