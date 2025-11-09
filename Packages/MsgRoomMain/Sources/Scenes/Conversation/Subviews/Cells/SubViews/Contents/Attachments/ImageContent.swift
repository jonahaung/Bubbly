//
//  ImageContent.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 6/7/24.
//

import Core
import Database
import ImageLoader
import Services
import SwiftUI
import VideoLoader
import XUI

extension AttachmentContent {
    struct ImageContent: View {
        let attachment: Attachment
        @Environment(MsgCellViewModel.self) private var viewModel
        @Environment(\.sendChatRoomAction) private var msgRoomAction
        @Environment(\.attachmentFetcher) private var attachmentFetcher
        @State private var isLoading = false
        @State private var error: Error?

        @ViewBuilder
        var body: some View {
            if let image = viewModel.attachment.thumbnail {
                imageView(for: image)
            } else {
                ProgressView()
                    .controlSize(.mini)
                    .task(id: viewModel.isVisible, priority: .userInitiated) {
                        if viewModel.isVisible {
                            if viewModel.msg.fileExist(), let image = viewModel.msg.thumbnailImage() {
                                viewModel.attachment.thumbnail = image
                            } else {
                                await loadAttachmentIfNeeded()
                            }
                        }
                    }
            }
        }

        func loadAttachmentIfNeeded() async {
            guard viewModel.isVisible else { return }
            if viewModel.attachment.thumbnail != nil { return }
            if await hasLocalFile() {
                await loadLocalFile()
            } else {
                await loadAttachmentData()
            }
        }

        func hasLocalFile() async -> Bool {
            viewModel.msg.fileExist()
        }

        func loadLocalFile() async {
            if let image = viewModel.msg.thumbnailImage() {
                await MainActor.run {
                    viewModel.attachment.thumbnail = image
                    viewModel.layoutIfNeeded()
                }
            } else {
                await loadAttachmentData()
            }
        }

        func loadAttachmentData() async {
            await MainActor.run {
                isLoading = true
                error = nil
            }

            do {
                let data = try await attachmentFetcher?.fetch(viewModel.msg.uid)

                await MainActor.run {
                    if let data = data?.data, let image = UIImage(data: data) {
                        viewModel.attachment.thumbnail = image
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isLoading = false
                    Log("Failed to load attachment: \(error)")
                }
            }
        }

        func onImageLoaded(_ image: UIImage) {
            let msg = viewModel.msg
            Task.detached {
                do {
                    let data = try MediaManager.shared.createData(from: image)
                    let thumbnailData = try await MediaManager.shared.createThumbnail(from: image)
                    try msg.file()?.write(data)
                    try msg.thumbnailFile()?.write(thumbnailData)
                } catch {
                    Log(error)
                }
            }
        }

        private func imageView(for image: UIImage) -> some View {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .equatable(by: attachment.uid)
                .sheetWithZoomTransition {
                    if let file = viewModel.msg.file() {
                        FileImageViewer(file)
                            .statusBarHidden(true)
                    }
                }
        }
    }
}
