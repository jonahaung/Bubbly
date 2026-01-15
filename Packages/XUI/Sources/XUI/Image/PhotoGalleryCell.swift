//
//  PhotoGalleryCell.swift
//  XUI
//
//  Created by Aung Ko Min on 29/12/25.
//


import SwiftUI
import ImageLoader

public struct PhotoGalleryCell: View {
	
	private let item: any PhotoGalleryItem
    @Environment(\.dismiss) private var dismiss

    public init(_ item: any PhotoGalleryItem, title: String = "") {
		self.item = item
    }

    public var body: some View {
		LazyImage(url: item.galleryURL, transaction: .withAnimation()) { state in
			switch state.result {
			case .success(let success):
				Image(uiImage: success.image)
					.resizable()
					.scaledToFit()
					.zoomable()
			case .failure(let failure):
				ContentUnavailableView {
					Text("Error")
				} description: {
					Text(failure.localizedDescription)
				}
			case .none:
				ProgressView().controlSize(.mini)
			}
		}
    }
}
