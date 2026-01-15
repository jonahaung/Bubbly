//
//  AttachmentGalleryCell.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 29/12/25.
//

import XUI
import Database
import SwiftUI
import ImageLoader
import WebKit
import _AVKit_SwiftUI

public struct AttachmentGalleryCell: View {

	let attachment: Attachment
	@State private var webPage: WebPage?
	@Environment(\.openURL) private var openURL

	@ViewBuilder
	public var body: some View {
		switch attachment.attachmentType {
		case .image, .imageUploading:
			if let data = attachment.data(), let uiImage = UIImage(data: data) {
				Image(uiImage: uiImage)
					.resizable()
					.scaledToFit()
					.zoomable()
			} else {
				content
			}
		case .link:
			VStack(spacing: 8) {
				if let data = attachment.data(), let uiImage = UIImage(data: data) {
					Image(uiImage: uiImage)
						.resizable()
						.scaledToFit()
				} else {
					content
				}
				if let title = attachment.title {
					VStack(alignment: .leading, spacing: 8) {
						Text(title)
							.font(.headline)
						if let subTitle = attachment.subTitle {
							Text(subTitle)
								.font(.subheadline)
								.foregroundStyle(.secondary)
								.lineHeight(.leading(increase: 2))
						}

						if let url = URL(string: attachment.url) {
							Link(destination: url) {
								Label(url.host() ?? url.absoluteString, systemImage: "globe.fill")
							}
						}
					}
					.flexible(.horizontal)
					.multilineTextAlignment(.leading)
				}
				Spacer()
				Button {
					if let url = URL(string: attachment.url) {
						openURL(url)
					}
				} label: {
					Text("Open in Safari")
						.flexible(.horizontal)
				}
				.buttonStyle(.roundedButtonStyle)
				.padding(.horizontal)
			}.padding()
		case .video, .videoUploading:
			VideoAttachmentView(attachment: attachment)
		}
	}

	private var content: some View {
		AsyncImage(url: attachment.galleryURL) { image in
			image
				.resizable()
				.scaledToFit()
				.zoomable()
		} placeholder: {
			ProgressView().controlSize(.mini)
		}
	}
}
