//
//  LinkContent.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 19/9/25.
//

import Core
import Database
import ImageLoader
import Services
import SwiftUI
import VideoLoader
import WebKit
import XUI

extension AttachmentContent {
    struct LinkContent: View {
        @State private var attachment: Attachment
        @Environment(MsgCellViewModel.self) private var viewModel
        @Environment(\.attachmentFetcher) private var attachmentFetcher

        // MARK: - Initialization

        init(attachment: Attachment) {
            _attachment = State(initialValue: attachment)
        }

        // MARK: - Body

        var body: some View {
            Group {
                if let image = viewModel.attachment.thumbnail {
                    imageView(for: image)
                } else {
                    loadingView
                        .task(id: viewModel.isVisible, priority: .userInitiated) {
                            if viewModel.isVisible {
                                await loadAttachmentIfNeeded()
                            }
                        }
                }
            }
        }
    }
}

// MARK: - View Components

private extension AttachmentContent.LinkContent {
    var loadingView: some View {
        ProgressView()
            .controlSize(.mini)
    }

    var errorView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)

            Text("Failed to load preview")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Retry") {
                Task {
                    await loadAttachmentData()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding()
    }

    var invalidURLView: some View {
        VStack(spacing: 8) {
            Image(systemName: "link")
                .foregroundColor(.red)

            Text("Invalid URL")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(attachment.url)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    func imageView(for image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .equatable(by: attachment.uid)
            .presentSheet {
                WebView(url: .init(string: attachment.url))
                    .ignoresSafeArea(.all)
                    .presentationDetents([.medium, .large])
            }
    }
}

// MARK: - Private Methods

private extension AttachmentContent.LinkContent {
    func loadAttachmentIfNeeded() async {
        guard viewModel.isVisible else { return }
        if viewModel.attachment.thumbnail != nil { return }
        if await hasLocalFile() {
            await loadLocalFile()
        } else {
            await loadAttachmentData()
        }
    }

    func loadAttachmentData() async {
        do {
            let data = try await attachmentFetcher?.fetch(viewModel.msg.uid)

            await MainActor.run {
                if let data = data?.data, let image = UIImage(data: data) {
                    viewModel.attachment.thumbnail = image
                }
            }
        } catch {
            Log("Failed to load attachment: \(error)")
        }
    }

    func loadLocalFile() async {
        if let image = viewModel.msg.thumbnailImage() {
            await MainActor.run {
                self.viewModel.attachment.thumbnail = image
                self.viewModel.layoutIfNeeded()
            }
        } else {
            await loadAttachmentData()
        }
    }

    func hasLocalFile() async -> Bool {
        viewModel.msg.fileExist()
    }
}
