//  ImageUploadingLayer.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database
import Services
import ImageLoader
import VideoLoader

struct ImageUploadingLayer: View {

    let attachment: Attachment
    let url: URL
    let conversationID: String
    let onCompleteUpload: ((_ newValue: Attachment) -> Void)?

    var body: some View {
        ZStack(alignment: .center) {
            if let error {
                Button(action: retryUpload) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Retry photo upload")
                .accessibilityHint(error.localizedDescription)
            } else if let progress {
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
            await startUpload()
        }
    }

    @Environment(MsgCellViewModel.self) private var viewModel
    
    @State private var progress: ImageTask.Progress?
    @State private var uploading = false
    @State private var error: Error?

    private let uploader: ImageUploadingService = .init()

    private func startUpload() async {
        guard !uploading else {
            return
        }

        uploading = true
        error = nil
        defer { uploading = false }
        let attachmentID = attachment.uid
        let conID = conversationID

        do {
            let url = try await uploader.uploadFile(
                url,
                to: .conversation(conID: conID, attachmentID: attachmentID)
            ) { progress in
                Task { @MainActor in
                    if let progress {
                        self.progress = if progress.completedUnitCount == progress.totalUnitCount {
                            nil
                        } else {
                            .init(
                                completed: progress.completedUnitCount,
                                total: progress.totalUnitCount
                            )
                        }
                    }
                }
            }
            await MainActor.run {
                var newValue = attachment
                newValue.url = url.absoluteString
                newValue.attachMentTypeRaw = AttachMentType.image.rawValue
                onCompleteUpload?(newValue)
            }
        } catch is CancellationError {
        } catch {
            self.error = error
        }
    }

    private func retryUpload() {
        error = nil
        Task {
            await startUpload()
        }
    }
}
