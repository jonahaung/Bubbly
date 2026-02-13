import MediaPicker
import PhotosUI
import Services
import SwiftUI

@MainActor protocol PhotoPickerManagerDelegate: AnyObject {
	func photoPickerManager(_ manager: PhotoPickerManager, didSelectImages images: [SelectedImage])
}

@MainActor
@Observable
final class PhotoPickerManager {
	private var items: [SelectedPhotoItem] = [] {
		didSet {
			scheduleDebouncedUpdate()
		}
	}

	var photoPickerItems: Binding<[PhotosPickerItem]> {
		.init {
			self.items.map(\.item)
		} set: { newValue in
			self.items = newValue.map { SelectedPhotoItem($0) }
		}
	}

	var selectedImages = [SelectedImage]()

	private var debounceTask: Task<Void, Never>?
	private let debounceInterval: Duration = .milliseconds(350)
	weak var delegate: PhotoPickerManagerDelegate?

	init() {}

	func remove(for id: SelectedPhotoItem.ID) {
		removeSelectedImages(withIDs: [id])
	}

	func removeAll() {
		let ids = Set(items.map(\.id)).union(selectedImages.map(\.id))
		removeSelectedImages(withIDs: Array(ids))
	}

	func removeSelectedImages(withIDs ids: [SelectedPhotoItem.ID]) {
		guard !ids.isEmpty else { return }

		selectedImages.removeAll { ids.contains($0.id) }
		items.removeAll { ids.contains($0.id) }
	}

	private func scheduleDebouncedUpdate() {
		debounceTask?.cancel()

		let snapshots = items

		debounceTask = Task.detached(priority: .background) { [weak self] in
			guard let strongSelf = self else { return }

			try? await Task.sleep(for: strongSelf.debounceInterval)
			guard !Task.isCancelled else { return }

			let images = await PhotoPickerManager.processSelections(snapshots)
			guard !Task.isCancelled else { return }

			await MainActor.run {
				strongSelf.selectedImages = images
				strongSelf.delegate?.photoPickerManager(strongSelf, didSelectImages: images)
			}
		}
	}

	private nonisolated static func processSelections(_ selections: [SelectedPhotoItem]) async
		-> [SelectedImage]
	{
		var results = [SelectedImage]()
		results.reserveCapacity(selections.count)

		for item in selections {
			if Task.isCancelled { break }
			if let image = await decodeImage(from: item) {
				results.append(image)
			}
		}

		return results
	}

	private nonisolated static func decodeImage(from photo: SelectedPhotoItem) async
		-> SelectedImage?
	{
		guard let data = await loadImageData(from: photo) else { return nil }
		guard let uiImage = UIImage(data: data) else { return nil }
		return SelectedImage(id: photo.id, image: uiImage)
	}

	private nonisolated static func loadImageData(from photo: SelectedPhotoItem) async -> Data? {
		try? await withTaskCancellationHandler(
			operation: {
				try await photo.loadTransferable(type: Data.self)
			},
			onCancel: {}
		)
	}
}
