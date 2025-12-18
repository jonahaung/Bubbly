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

@MainActor
@Observable
final class ImagePickerViewModel {
    var selections = [SelectedPhoto]()
    var processedPhotos = [SelectedPhoto.ID: UIImage]()

    init() {
        UserDefaults.standard.set(nil, forKey: "cachedSelection")
        if !cachedSelection.isEmpty {
            selections = cachedSelection.map {
                SelectedPhoto(itemIdentifier: $0)
            }
        }
    }

    func loadPhoto(_ item: SelectedPhoto) async {
        var data: Data? = try? await item.loadTransferable(type: Data.self)
        if let cachedData = getCachedData(for: item.id) { data = cachedData }
        guard let data, let uiImage = UIImage(data: data)?.resized(toWidth: 200) else { return }
        processedPhotos[item.id] = uiImage
        cacheData(item.id, data)
    }

    var selection: SelectedPhoto? {
        get {
            selections.first
        }
        set {
            if let newValue {
                selections = [newValue]
            } else {
                selections = []
            }
        }
    }

    var photoPickerItems: [PhotosPickerItem] {
        get {
            selections.map(\.item)
        }
        set {
            Task { @MainActor in
                self.selections = newValue.map { item in .init(item) }
            }
        }
    }

    var photoPickerItem: PhotosPickerItem? {
        get {
            selection?.item
        }
        set {
            Task { @MainActor in
                if let newValue {
                    self.selection = .init(newValue)
                } else {
                    self.selection = nil
                }
            }
        }
    }

    func remove(for id: SelectedPhoto.ID) {
        selections.removeAll(where: { $0.id == id })
        processedPhotos.removeValue(forKey: id)
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
        }

        if !cachedSelection.contains(where: { $0 == id }) {
            cachedSelection.append(id)
            let url = cachedDirectory.appendingPathComponent("\(id)")
            try? data.write(to: url)
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
            selections.contains(where: { $0.id == element.key })
        }
    }

    private var cachedDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
