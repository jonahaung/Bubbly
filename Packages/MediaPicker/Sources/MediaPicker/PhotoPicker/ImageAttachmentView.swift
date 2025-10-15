//
//  ImageAttachmentViewerView.swift
//  InlinePhotosPickerDemo
//
//  Created by Aung Ko Min on 25/6/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import PhotosUI

public struct ImageAttachmentViewerView: View {

	@State var imageAttachment: ImageAttachment
    public init(imageAttachment: ImageAttachment) {
        self.imageAttachment = imageAttachment
    }

    public var body: some View {
        HStack {
            switch imageAttachment.imageStatus {
            case .finished(let image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
            default:
                ProgressView()
            }
		}.task(id: imageAttachment.identifier) {
            await imageAttachment.loadImage()
        }
    }
}
