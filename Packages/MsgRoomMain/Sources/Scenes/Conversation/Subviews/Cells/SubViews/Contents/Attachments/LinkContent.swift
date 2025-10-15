//
//  LinkContent.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 19/9/25.
//

import SwiftUI
import ImageLoader
import Database
import Services
import Core
import XUI
import VideoLoader
import WebKit

extension AttachmentContent {
	struct LinkContent: View {
		@State var attachment: Attachment
		@Environment(MsgCellViewModel.self) private var viewModel

		@ViewBuilder
		var body: some View {
			if let data = attachment.thumbnailData, let image = UIImage(data: data), let url = URL(string: attachment.url) {
				Image(uiImage: image)
					.resizable()
					.scaledToFit()
					.presentSheet {
						WebView(url: url)
							.presentationDetents([.medium, .large])
					}
			} else {
				if let url = URL(string: attachment.url) {
					LinkPreviewView(url)
						.onCompletion{ data in
							Task {
								if let image = data.image, let imageData = try? await MediaManager.shared.createThumbnil(from: image) {
									var msg = viewModel.msg
									msg.attachment?.thumbnailData = imageData
									Task {
										try? await Store.shared.msgStore.updateAndSave(uid: viewModel.msg.uid, { msg in
											msg.attachment?.thumbnailData = imageData
										})
									}
									viewModel.update(with: msg)
								}
							}
						}
				} else {
					Text("Error Link \(attachment.url)")
				}
			}
		}
	}
}
