//
//  MarkdownContent.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 19/9/25.
//

import SwiftUI
import XUI

struct MarkdownContent: View {
	let text: String
	let elements: [MarkdownElement]
	var body: some View {
		MarkdownView(elements: elements, text: text)
			.padding(.horizontal, 12)
			.padding(.vertical, 6)
			.fixedSize(horizontal: false, vertical: true)
			.equatable(by: text)
	}
}
