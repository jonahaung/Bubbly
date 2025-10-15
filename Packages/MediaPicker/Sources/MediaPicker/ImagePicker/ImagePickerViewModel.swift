//
//  ImagePickerViewModel.swift
//  MediaPicker
//
//  Created by Aung Ko Min on 1/10/25.
//


import SwiftUI
import PhotosUI

@MainActor
@Observable
final class ImagePickerViewModel {

	var selection: Binding<[SelectedPhoto]>

	init(selection: Binding<[SelectedPhoto]>) {
		self.selection = selection
		if !cachedSelection.isEmpty {
			self.selection.wrappedValue = selection.wrappedValue.map {
				SelectedPhoto(itemIdentifier: $0.id)
			}
		}
	}
	var processedPhotos = [SelectedPhoto.ID: StickerResult]()
	var invalidPhotos: [SelectedPhoto.ID] = []

	func loadPhoto(_ item: SelectedPhoto) async {
		var data: Data? = try? await item.loadTransferable(type: Data.self)

		if let cachedData = getCachedData(for: item.id) { data = cachedData }

		guard let data, let image = UIImage(data: data) else { return }
		processedPhotos[item.id] = .init(id: item.id, uiImage: image)

		cacheData(item.id, data)
	}

	func processAllPhotos() async {
//		let results = await selection.parallelMap { item -> StickerResult? in
//			guard self.processedPhotos[item.id] == nil else { return nil }
//			let data = await self.getData(for: item)
//			let photo = try? await StickerProcessor().process(data: data)
//			return photo.map { StickerResult(id: item.id, sticker: $0) }
//		}.compactMap{ $0 }
//		results.forEach { result in
//			processedPhotos[result.id] = result.sticker
//		}
		//        await withTaskGroup { [self] group in
		//            for item in selection {
		//                guard processedPhotos[item.id] == nil else { continue }
		//				group.addTask { [self] in
		//                    let data = await getData(for: item)
		//                    let photo = try? await StickerProcessor().process(data: data)
		//					return photo.map { StickerResult(id: item.id, sticker: $0) }
		//                }
		//            }
		//
		//            for await result in group {
		//                if let result {
		//					processedPhotos[result.id] = result.sticker
		//                }
		//            }
		//        }
	}

	var photosPickerSelection: Binding<[PhotosPickerItem]> {
		let selection = self.selection
		return Binding(
			get: { selection.wrappedValue.map { $0.item } },
			set: { value in Task { @MainActor in
				self.selection.wrappedValue = value.map { item in .init(item) }
			}
			}
		)
	}

	@concurrent
	func getData(for item: SelectedPhoto) async -> Data {
		var data = try? await item.loadTransferable(type: Data.self)
		if let cachedData = await getCachedData(for: item.id) { data = cachedData }
		await cacheData(item.id, data!, updateState: false)
		return data!
	}

	func getCachedData(for id: SelectedPhoto.ID) -> Data? {
		if cachedSelection.contains(where: { $0 == id }) {
			try? Data(contentsOf: cachedDirectory.appendingPathComponent("\(id)"))
		} else { nil }
	}

	func cacheData(_ id: SelectedPhoto.ID, _ data: Data, updateState: Bool = true) {
		if updateState {
			updateProcessedPhotos()
			updateInvalidPhotos(for: id)
		}

		if !cachedSelection.contains(where: { $0 == id }) {
			cachedSelection.append(id)
			let url = cachedDirectory.appendingPathComponent("\(id)")
			try! data.write(to: url)
		}
	}

	var cachedSelection: [SelectedPhoto.ID] {
		get {
			UserDefaults.standard.array(
				forKey: "cachedSelection"
			) as? [SelectedPhoto.ID] ?? []
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "cachedSelection")
		}
	}

	private func updateProcessedPhotos() {
		processedPhotos = processedPhotos.filter { element in
			selection.contains(where: { $0.id == element.key })
		}
	}

	private func updateInvalidPhotos(for id: SelectedPhoto.ID) {
		if processedPhotos[id] == nil {
			invalidPhotos.append(id)
		}
	}

	private var cachedDirectory: URL {
		FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	}

}
