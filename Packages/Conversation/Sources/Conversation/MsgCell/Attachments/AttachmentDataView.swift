//
//  AttachmentDataView.swift
//  Conversation
//
//  Created by Aung Ko Min on 25/5/26.
//

import SwiftUI
import Services
import Core

struct AttachmentDataView: View {
    
    let data: AttachmentData
    let onTap: () -> Void
    
    var body: some View {
        switch data {
        case let .image(thumbnail):
            imageView(for: thumbnail)
        case let .link(thumbnail):
            imageView(for: thumbnail)
        case let .imageUpload(url, thumbnail):
            imageView(for: thumbnail)
        case .video(videoURL: _, thumbnail: let thumbnail):
            imageView(for: thumbnail)
        }
    }
    
    private func imageView(for uiImage: UIImage) -> some View {
        Button(action: onTap) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        }
        .accessibilityLabel("Open attachment")
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
    }
}
