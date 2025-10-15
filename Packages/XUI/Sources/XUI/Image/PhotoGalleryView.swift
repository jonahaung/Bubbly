//
//  PhotoGalleryView.swift
//  Msgr
//
//  Created by Aung Ko Min on 18/1/23.
//

import SwiftUI

public struct PhotoGalleryView: View {

	private let attachments: [XAttachment]
	@Binding private var selection: Int
	private let title: String
	@Environment(\.dismiss) private var dismiss

	public init(attachments: [XAttachment], title: String, selection: Binding<Int>) {
		self.attachments = attachments
		self.title = title
		self._selection = selection
	}

	public var body: some View {
		content
	}

	private var content: some View {
		NavigationView {
			TabView(selection: $selection) {
				ForEach(Array(attachments.enumerated()), id: \.offset) { (index, item) in
					AttachmentViewerView(item)
						.tag(index)
				}
			}
			.tabViewStyle(.page(indexDisplayMode: .never))
			.navigationBarTitle(title, displayMode: .inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					DismissButton(dismiss: dismiss)
				}
			}
			.overlay(alignment: .bottom) {
				if attachments.count > 1 {
					XPhotoPageControl(selection: $selection, length: attachments.count, size: 10)
				}
			}
		}
		.colorScheme(.dark)
		.tint(Color.white.gradient)
		.statusBarHidden(true)
	}
}
