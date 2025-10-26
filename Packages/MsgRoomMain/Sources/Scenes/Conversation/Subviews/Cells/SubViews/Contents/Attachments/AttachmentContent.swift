//
//  AttachmentContent.swift
//  Conversation
//
//  Created by Aung Ko Min on 31/1/22.
//

import SwiftUI
import Database
import Services

struct AttachmentContent: View {

	let attachment: Attachment
	@Environment(MsgCellViewModel.self) private var viewModel
	@Environment(\.attachmentFetcher) private var attachmentFetcher

	var body: some View {
		ZStack {
			Rectangle().fill(Color.systemGray6)
				.frame(size: attachment.bestFitSize)
				.layoutPriority(1)
			switch attachment.attachmentType {
			case .image:
				ImageContent(attachment: attachment)
			case .imageUploading:
				ImageUploadingContent(attachment: attachment)
			case .video:
				fatalError()
			case .videoUploading:
				fatalError()
			case .link:
				LinkContent(attachment: attachment)
					.frame(size: attachment.bestFitSize)
					.overlay(alignment: .bottom) {
						Text(viewModel.msg.text).font(.system(size: 8, weight: .medium).width(.compressed)).padding(4)
							.lineLimit(2)
							.multilineTextAlignment(.center)
					}
			}
		}
	}
}
