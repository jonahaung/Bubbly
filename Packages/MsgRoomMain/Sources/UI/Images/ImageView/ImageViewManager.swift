//
//  ImageViewManager.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import SwiftUI
import Services
import ImageLoader
import XUI

@MainActor
@Observable
final class ImageViewManager {
	
	let item: ImageView.Item
	private let mediaManager = MediaManager.shared
	var image: UIImage?

	init(item: ImageView.Item) {
		self.item = item
	}

	func isLocallyCached() -> Bool {
		mediaManager.fileExist(for: item.imageID, .png)
	}
	@concurrent
	func onAppear() async {
//		guard await image == nil else { return }
		if let image = UIImage(contentsOfFile: mediaManager.path(for: item.imageID, .png)) {
			await MainActor.run {
				self.image = image
			}
		}
	}

	func onCompletion(_ result: (Result<ImageResponse, Error>)) {
		switch result {
		case .success(let success):
			Task {
				try? await saveImage(success.image)
			}
		case .failure:
			break
		}
	}
	func onStart(_ imageTask: ImageTask) {
		print(imageTask)
	}
	func getURL() -> URL {
		return item.url
	}

	@concurrent
	func saveImage(_ uiImage: UIImage) async throws {
		let data = try mediaManager.createData(from: uiImage)
		try mediaManager.save(item.imageID, data: data, .png)
		let thumbData = try mediaManager.createData(from: uiImage)
		try mediaManager.saveThumbnil(item.imageID, data: thumbData, .png)
	}
}
