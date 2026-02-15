import Database
import ImageLoader
import SwiftUI
import XUI

@MainActor
@Observable
final class ImageViewManager {
	let item: any ImageViewItem
	var image: UIImage?
	var progress: ImageTask.Progress?

	init(item: any ImageViewItem) {
		self.item = item
	}

	func isLocallyCached() -> Bool {
		item.fileExist()
	}

	@concurrent func loadLocalImage() async {
		guard await image == nil else {
			return
		}
		guard await isLocallyCached() else { return }
		if let image = item.thumbnailImage() {
			await MainActor.run {
				self.image = image
			}
		}
	}

	func onCompletion(_ result: Result<ImageResponse, Error>) {
		switch result {
		case let .success(success):
			Task {
				do {
					try await self.saveImage(success.image)
					await loadLocalImage()
				} catch {
					log(error)
				}
			}
		case .failure:
			break
		}
	}

	func onStart(_ imageTask: ImageTask) {
		Task {
			for await progress in imageTask.progress {
				self.progress = progress
			}
		}
	}

	func getURL() -> URL? {
		if let url = URL(
			string: "https://media2.dev.to/dynamic/image/width=800%2Cheight=%2Cfit=scale-down%2Cgravity=auto%2Cformat=auto/https%3A%2F%2Fi.pravatar.cc%2F250%3Fu%3Dmail%40ashallendesign.co.uk"
		) {
			return url
		}
		return item.remoteURL
	}

	@concurrent
	func saveImage(_ uiImage: UIImage) async throws {
		let mediaManager = MediaManager.shared
		let data = try mediaManager.createData(from: uiImage)
		try item.file()?.write(data)
		let thumbData = try mediaManager.createData(from: uiImage)
		try item.thumbnailFile()?.write(thumbData)
	}
}
