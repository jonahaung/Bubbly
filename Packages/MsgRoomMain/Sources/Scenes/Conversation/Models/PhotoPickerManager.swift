/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 A sticker view data model for managing imported, processed,
 and exported photos, as well as their current state.
 */

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
			self.items = newValue.map{ SelectedPhotoItem($0) }
		}
	}
	
	var selectedImages = [SelectedImage]()

	private var debounceTask: Task<Void, Never>?
	private let debounceInterval: Duration = .milliseconds(350)
	weak var delegate: PhotoPickerManagerDelegate?

	init() {}

	/// Remove a specific photo by ID (keeps existing call sites working)
	func remove(for id: SelectedPhotoItem.ID) {
		removeSelectedImages(withIDs: [id])
	}

	/// Remove all items (both selections and images) in one go
	func removeAll() {
		let ids = Set(selectedImages.map(\.id)).union(items.map(\.id))
		removeSelectedImages(withIDs: Array(ids))
	}

	/// Remove by IDs; updates both selectedImages and selections atomically
	func removeSelectedImages(withIDs ids: [SelectedPhotoItem.ID]) {
		guard !ids.isEmpty else { return }

		// Remove from selectedImages first to avoid flicker (no debounce tied to this)
		if !selectedImages.isEmpty {
			selectedImages.removeAll { ids.contains($0.id) }
		}

		// Remove corresponding selections (this will trigger one debounced update)
		if !items.isEmpty {
			items.removeAll { ids.contains($0.id) }
		}
		selectedImages.removeAll { ids.contains($0.id )}
	}
	// MARK: - Debounced update

	private func scheduleDebouncedUpdate() {
		// Cancel previous task
		debounceTask?.cancel()

		// Take snapshot of current state
		let snapshots = items

		debounceTask = Task { [weak self] in
			guard let strongSelf = self else { return }

			// Wait for debounce interval
			try? await Task.sleep(for: strongSelf.debounceInterval)

			// Check cancellation after sleep
			guard !Task.isCancelled else { return }

			// Process images off-main
			let images = await PhotoPickerManager.processSelections(snapshots)

			// Check cancellation after processing
			guard !Task.isCancelled else { return }

			// Update UI on main thread
			await MainActor.run {
				strongSelf.selectedImages = images
				strongSelf.delegate?.photoPickerManager(strongSelf, didSelectImages: images)
			}
		}
	}

	// MARK: - Helpers (off-main)

	/// Process multiple selections into decoded images
	private nonisolated static func processSelections(_ selections: [SelectedPhotoItem]) async -> [SelectedImage] {
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

	/// Decode a single image from SelectedPhoto
	private nonisolated static func decodeImage(from photo: SelectedPhotoItem) async -> SelectedImage? {
		guard let data = await loadImageData(from: photo) else { return nil }
		// Decode off-main thread
		guard let uiImage = UIImage(data: data) else { return nil }
		return SelectedImage(id: photo.id, image: uiImage)
	}

	/// Load image data with cancellation support
	private nonisolated static func loadImageData(from photo: SelectedPhotoItem) async -> Data? {
		return try? await withTaskCancellationHandler(
			operation: {
				try await photo.loadTransferable(type: Data.self)
			},
			onCancel: {}
		)
	}
}
