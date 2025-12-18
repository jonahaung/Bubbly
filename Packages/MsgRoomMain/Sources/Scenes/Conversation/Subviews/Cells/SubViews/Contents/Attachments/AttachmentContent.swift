//
//  AttachmentContent.swift
//  Conversation
//
//  Created by Aung Ko Min on 31/1/22.
//

import Database
import Services
import SwiftUI

struct AttachmentContent: View {
	let attachment: Attachment
	@Environment(MsgCellViewModel.self) private var viewModel

	var body: some View {
		ZStack {
			Rectangle().fill(Color.clear)
				.frame(size: attachment.bestFitSize)
				.layoutPriority(1)
			if viewModel.isVisible {
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
}
