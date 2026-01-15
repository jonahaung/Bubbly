//
//  MsgCell+Content+Text.swift
//  Conversation
//
//  Created by Aung Ko Min on 31/1/22.
//

import SwiftUI
import XUI

extension MsgCell {

	struct TextContent: View {

		let text: String
		@Environment(\.typography) var typography

		var body: some View {
			Text(.init(text))
				.font(typography.body)
				.lineHeight(.multiple(factor: 1.2))
				.lineSpacing(1)
				.equatable(by: text)
		}
	}

}
