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

    private enum UploadState {
        case uploading
        case failed(Error)
        case completed
    }

    var body: some View {
        ZStack(alignment: .center) {
            switch state {
            case .uploading:
                if let progress {
                    ProgressView(value: progress)
                        .tint(.white)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.45), in: .circle)
                        .accessibilityLabel("Uploading photo")
                        .accessibilityValue("\(Int(progress * 100)) percent")
                } else {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.45), in: .circle)
                        .accessibilityLabel("Uploading photo")
                }
            case .failed(let error):
                Button {
                    retryCount += 1
                } label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Retry photo upload")
                .accessibilityHint(error.localizedDescription)
            case .completed:
                EmptyView()
            }
        }
        .task(id: uploadID) {
            await upload()
        }
        .onChange(of: inputID) {
            syncInput()
        }
    }

    @State private var state: UploadState = .uploading
    @State private var progress: Double?
    @State private var retryCount = 0
    @State private var uploadTaskID: String?

    private let uploader: ImageUploadingService = .init()

    private var inputID: String {
        "\(conversationID):\(attachment.uid):\(url.absoluteString)"
    }

    private var uploadID: String {
        "\(inputID):\(retryCount)"
    }

    private func upload() async {
        guard uploadTaskID != uploadID else { return }
        uploadTaskID = uploadID
        state = .uploading
        progress = nil
        do {
            let uploadedURL = try await uploader.uploadFile(
                url,
                to: .conversation(conID: conversationID, attachmentID: attachment.uid)
            ) { progress in
                let fraction = progress.flatMap { value -> Double? in
                    guard value.totalUnitCount > 0 else { return nil }
                    return min(max(Double(value.completedUnitCount) / Double(value.totalUnitCount), 0), 1)
                }
                Task { @MainActor in
                    guard !Task.isCancelled else { return }
                    self.progress = fraction
                }
            }
            try Task.checkCancellation()
            var newValue = attachment
            newValue.url = uploadedURL.absoluteString
            newValue.attachMentTypeRaw = AttachMentType.image.rawValue
            onCompleteUpload?(newValue)
            state = .completed
        } catch is CancellationError {
            if uploadTaskID == uploadID {
                uploadTaskID = nil
            }
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error)
        }
    }

    private func syncInput() {
        guard let uploadTaskID, !uploadTaskID.hasPrefix(inputID) else { return }
        self.uploadTaskID = nil
        retryCount = 0
        state = .uploading
        progress = nil
    }
}
