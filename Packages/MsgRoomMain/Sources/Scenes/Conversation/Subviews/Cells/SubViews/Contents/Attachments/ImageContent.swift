//
//  ImageContent.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 6/7/24.
//

import SwiftUI
import ImageLoader
import Database
import Services
import Core
import XUI
import VideoLoader

extension AttachmentContent {
	struct ImageContent: View {
		
		let attachment: Attachment
		@Environment(MsgCellViewModel.self) private var viewModel
		@Environment(\.invokeMsgRoomAction) private var msgRoomAction

		@ViewBuilder
		var body: some View {
			if let data = attachment.thumbnailData, let uiImage = UIImage(data: data) {
				Image(uiImage: uiImage)
					.resizable()
					.scaledToFit()
					.sheetWithZoomTransition {
						AttachmentViewer(attachment)
							.statusBarHidden(true)
					}
			} else {
				LazyImage(
					url: .init(string: attachment.url)
				) { state in
					switch state.result {
					case .success(let image):
						Image(uiImage: image.image)
							.resizable()
							.scaledToFit()
					case .failure:
						SystemImage(.exclamationmarkCircleFill)
							.symbolRenderingMode(.multicolor)
					case .none:
						ProgressView().controlSize(.mini)
					}
				}
				.onCompletion { result in
					switch result {
					case .success(let imageResponse):
						onImageLoaded(imageResponse.image)
					case .failure(let error):
						print(error)
					}
				}
				.onDisappear(.cancel)
			}
		}

		public func onImageLoaded(_ image: UIImage) {
			let msg = viewModel.msg
			Task.detached { [self] in
				do {
					let data = try MediaManager.shared.createData(from: image)
					let thumbnailData = try await MediaManager.shared.createThumbnil(from: image)
					var newMsg = msg
					newMsg.attachment?.data = data
					newMsg.attachment?.thumbnailData = thumbnailData
					try await Store.shared.msgStore.updateAndSave(uid: newMsg.uid, { model in
						model.attachment = newMsg.attachment
					})
					await MainActor.run {
						viewModel.update(with: newMsg)
					}
				} catch {
					Log(error)
				}
			}
		}
	}
}
