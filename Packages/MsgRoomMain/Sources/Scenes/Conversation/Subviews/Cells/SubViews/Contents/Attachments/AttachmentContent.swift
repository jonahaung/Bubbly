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

	var body: some View {
		ZStack {
			Color.systemBackground
				.layoutPriority(-1)
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
			}
		}
	}
}
