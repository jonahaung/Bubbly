//
//  ImageViewManager.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import SwiftUI
import Services
import ImageLoader

@MainActor
@Observable
final class ImageViewManager {

	let item: ImageView.Item
	private let mediaManager = MediaManager.shared

	init(item: ImageView.Item) {
		self.item = item
	}

	func getURL() -> URL? {
		if mediaManager.thumbnilExist(for: item.id, item.type) {
			return mediaManager.thumbnilUrl(for: item.id, item.type)
		}
		if mediaManager.fileExist(for: item.id, item.type) {
			return mediaManager.url(for: item.id, item.type)
		}
		return item.url
	}

	@concurrent
	func saveImage(_ uiImage: UIImage) async throws {
		guard !mediaManager.thumbnilExist(for: item.id, item.type) else { return }
		let data = try mediaManager.createData(from: uiImage)
		let thumbData = try mediaManager.createData(from: uiImage)
		try mediaManager.save(item.id, data: data, .png)
		try mediaManager.saveThumbnil(item.id, data: thumbData, .png)
	}
}
