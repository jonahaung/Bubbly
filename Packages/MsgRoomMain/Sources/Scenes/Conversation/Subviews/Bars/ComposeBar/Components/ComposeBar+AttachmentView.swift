//
//  ComposeBar+Attachment.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 2/2/26.
//

import SwiftUI
import XUI

extension ComposeBar {
	struct ComposeBarAttachmentView: View {

		@Environment(ChatComposer.self) private var composer: ChatComposer

		var body: some View {
			ScrollView(.horizontal, showsIndicators: false) {
				HStack(alignment: .firstTextBaseline, spacing: 8) {
					ForEach(composer.attachments) { attachment in
						AttachmentPreview(attachment: attachment) {
							print($0)
						}
						.cornerRadius(8)
						.frame(maxWidth: 200, maxHeight: 100)
						.badgeView(
							Button {
								composer.removeAttachment(id: attachment.uid)
							} label: {
								SystemImage(.minus, 10)
									.foregroundStyle(Color.white)
									.padding(5)
									.background(Color.red, in: .circle)
							}
								.buttonStyle(.borderless)
						)
						.id(attachment.uid)
					}
				}.scrollTargetLayout()
			}
			.scrollPosition(id: .constant(composer.attachments.last?.uid))
			.scrollClipDisabled(false)
			.contentMargins(16, for: .scrollContent)
			.environment(\.viewIsVisible, true)
			.animation(.snappy, value: composer.attachments.count)
		}
	}
}
