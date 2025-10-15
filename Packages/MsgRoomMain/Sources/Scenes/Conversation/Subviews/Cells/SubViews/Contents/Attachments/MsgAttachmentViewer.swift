//
//  AttachmentViewerView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 27/9/25.
//


import SwiftUI
import ImageLoader
import Database

public struct AttachmentViewer: View {

	@State private var attachment: Attachment

	public init(
		_ attachment: Attachment
	) {
		self.attachment = attachment
	}
	public var body: some View {
		ZStack {
			Rectangle()
				.glassEffect(.regular.tint(Color.systemBackground.opacity(0.3)), in: .containerRelative)
				.ignoresSafeArea(.container, edges: .all)
			content
			VStack {
				toolBar
				Spacer()
			}
			.padding()
		}
	}

	@ViewBuilder
	private var content: some View {
		ZStack {
			if let data = attachment.data, let image = UIImage(data: data) {
				Image(uiImage: image)
					.resizable()
					.scaledToFit()

			} else {
				LazyImage(url: .init(string: attachment.url)) { state in
					switch state.result {
					case .success(let image):
						Image(uiImage: image.image)
							.resizable()
							.scaledToFit()
					case .failure(let error):
						Text(error.localizedDescription)
					case .none:
						ProgressView().controlSize(.mini)
					}
				}
			}
		}.zoomable()
	}

	private var toolBar: some View {
		HStack(alignment: .bottom) {
			Spacer()
			shareButton
		}
	}

	@ViewBuilder private var shareButton: some View {
		if let data = attachment.data, let fileImage = UIImage(
			data: data
		) {
			let image = Image(uiImage: fileImage)
			ShareLink(
				item: image,
				preview: SharePreview(attachment.url, icon: image)
			)
			.labelStyle(.iconOnly)
			.padding()
			.glassEffect(.regular.interactive(), in: .buttonBorder)
		} else {
			ShareLink(item: attachment.url, preview: SharePreview(attachment.url))
				.labelStyle(.iconOnly)
				.padding()
				.glassEffect(.regular.interactive(), in: .buttonBorder)
		}
	}
}

public struct MsgAttachmentViewer: View {

	private let attachment: Attachment
	private let title: String
	@Environment(\.dismiss) private var dismiss

	public init(_ attachment: Attachment, title: String = "") {
		self.attachment = attachment
		self.title = title
	}

	public var body: some View {
		AttachmentViewer(attachment)
			.statusBarHidden(true)
	}
}
