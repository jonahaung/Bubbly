//
//  ImageUploadingContent.swift
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

extension AttachmentContent {
	struct ImageUploadingContent: View {
		@State var attachment: Attachment
		@Environment(MsgCellViewModel.self) private var viewModel
		@State private var progress: ImageTask.Progress?
		@State private var uploading = false

		var body: some View {
			if let thumbnilImage = viewModel.msg.thumbnailImage() {
				Image(uiImage: thumbnilImage)
					.resizable()
					.scaledToFit()
					.overlay {
						if let progress {
							Gauge(value: progress.fraction) {
								Text("\(progress.fraction)")
							}
							.gaugeStyle(.accessoryCircularCapacity)
							.tint(Color.white.gradient)
							.frame(square: 150)
							.animation(.default, value: progress.completed)
						}
					}
					.task {
						guard !uploading, let image = viewModel.msg.image() else { return }
						uploading = true
						let msgID = viewModel.msg.uid
						let conID = viewModel.msg.conID
						let uploader = ImageUploadingService()
						do {
							let url = try await uploader.uploadImage(
								image,
								size: nil,
								to: .conversation(conID: conID, msgID: msgID)) { progress in
									Task { @MainActor in
										if let progress {
											if progress.completedUnitCount == progress.totalUnitCount {
												self.progress = nil
											} else {
												self.progress = .init(completed: progress.completedUnitCount, total: progress.totalUnitCount)
											}
										}
									}
								}
							var attachment = self.attachment
							attachment.url = url
							attachment.attachMentTypeRaw = AttachMentType.image.rawValue
							try await Store.shared.msgStore.updateAndSave(uid: msgID, { model in
								model.attachment?.url = url
								model.attachment?.attachMentTypeRaw = AttachMentType.image.rawValue
							})
							try await sendMessageWithAttachment(attachment)
						} catch {
							var attachment = self.attachment
							attachment.attachMentTypeRaw = AttachMentType.image.rawValue
							try? await Store.shared.msgStore.updateAndSave(uid: msgID, { model in
								model.attachment?.attachMentTypeRaw = AttachMentType.image.rawValue
							})
							Log(error)
						}
					}
			} else {
				Text("Error, no image data.")
			}
		}

		private func sendMessageWithAttachment(_ newAttachment: Attachment) async throws {
			var msg = viewModel.msg
			msg.attachment = newAttachment
			let conversation = try await ConversationRepo.getOrCreate(for: msg.conID, refetch: false)
			try await Socket.shared.send(.newMsg(rMsg: .init(msg)), conversation: conversation)
			await MainActor.run {
				self.viewModel.update(with: msg)
			}
		}
	}
}
