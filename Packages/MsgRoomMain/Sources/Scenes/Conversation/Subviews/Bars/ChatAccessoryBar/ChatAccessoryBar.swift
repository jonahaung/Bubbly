//
//  ChatAccessoryBar.swift
//  Msgr
//
//  Created by Aung Ko Min on 21/10/22.
//

import SFSafeSymbols
import SwiftUI
import XUI

struct ChatAccessoryBar: View {

	@Environment(ChatViewManager.self) private var manager
	@Environment(ChatComposer.self) private var composer
	@Namespace private var chatNoticeView
	
	var body: some View {
		HStack(alignment: .bottom) {
			if composer.attachments.isEmpty {
				switch manager.presentation.bottomAccessory {
				case .scrollDownButton:
					Spacer()
					CircleButton(.chevronDown) {
						manager.resetDatasource()
					}
//					.matchedGeometryEffect(
//						id: "chat_toast_view",
//						in: chatNoticeView,
//						properties: .frame,
//						anchor: .center
//					)
				case .contactAvator:
					Spacer()
//					if case let .contact(contact) = manager.conversation.kind {
//						ProfilePhoto(contact, size: .custom(15))
//							.matchedGeometryEffect(
//								id: "chat_toast_view",
//								in: chatNoticeView,
//								properties: .frame,
//								anchor: .center
//							)
//						
//						Spacer()
//					}
				}
			} else {
				attachmentsView()
			}
		}
		.padding(.horizontal, 8)
		.animation(.spring, value: manager.presentation.bottomAccessory)
		.geometryGroup()
	}
	
	private func attachmentsView () -> some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(alignment: .firstTextBaseline, spacing: 8) {
				ForEach(composer.attachments) { attachment in
					AttachmentPreview(attachment: attachment) {
						print($0)
					}
					.cornerRadius(8)
					.frame(maxWidth: 300, maxHeight: 150)
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
		.scrollClipDisabled()
		.contentMargins(.horizontal, 16, for: .scrollContent)
		.environment(\.viewIsVisible, true)
		.animation(.snappy, value: composer.attachments.count)
	}
}
