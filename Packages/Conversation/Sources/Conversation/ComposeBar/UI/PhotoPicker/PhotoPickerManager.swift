// © 2026 Aung Ko Min

#if os(iOS)
//
    // Copyright © 2026 Aung Ko Min. All rights reserved.
//

    import MediaPicker
    import PhotosUI
    import Services
    import SwiftUI

    @MainActor protocol PhotoPickerManagerDelegate: AnyObject {
        func photoPickerManager(
            _ manager: PhotoPickerManager,
            didSelectImages images: [SelectedImage],
        )
    }

    @MainActor
    @Observable
    final class PhotoPickerManager {
        private var items: [SelectedPhotoItem] = [] {
            didSet { scheduleDebouncedUpdate() }
        }

        var photoPickerItems: Binding<[PhotosPickerItem]> {
            .init(
                get: { self.items.map(\.item) },
                set: { self.items = $0.map(SelectedPhotoItem.init) },
            )
        }

        var selectedImages: [SelectedImage] = []

        private var debounceTask: Task<Void, Never>? = nil
        private let debounceInterval: Duration = .milliseconds(350)
        weak var delegate: PhotoPickerManagerDelegate? = nil

        private func scheduleDebouncedUpdate() {
            debounceTask?.cancel()
            let snapshot = items

            debounceTask = Task { [weak self] in
                guard let self else {
                    return
                }

                try? await Task.sleep(for: debounceInterval)
                guard !Task.isCancelled else {
                    return
                }

                let images = await processSelections(snapshot)
                guard !Task.isCancelled else {
                    return
                }

                guard snapshot.map(\.id) == items.map(\.id) else {
                    return
                }

                selectedImages = images
                delegate?.photoPickerManager(self, didSelectImages: images)
            }
        }

        private func processSelections(
            _ selections: [SelectedPhotoItem],
        ) async -> [SelectedImage] {
            await withTaskGroup(of: SelectedImage?.self) { group in
                for item in selections {
                    group.addTask {
                        await self.decodeImage(from: item)
                    }
                }

                var results = [SelectedImage]()
                results.reserveCapacity(selections.count)

                for await result in group {
                    if let result {
                        results.append(result)
                    }
                }

                return results
            }
        }

        private func decodeImage(
            from photo: SelectedPhotoItem,
        ) async -> SelectedImage? {
            let image = await ImageProcessingActor.shared.process(item: photo)
            guard let image else {
                return nil
            }

            return SelectedImage(id: photo.id, image: image)
        }

        func remove(for id: SelectedPhotoItem.ID) {
            removeSelectedImages(withIDs: [id])
        }

        func removeAll() {
            let ids = Set(items.map(\.id)).union(selectedImages.map(\.id))
            removeSelectedImages(withIDs: Array(ids))
            Task {
                await ImageProcessingActor.shared.removeAllFromCache()
            }
        }

        func removeSelectedImages(withIDs ids: [SelectedPhotoItem.ID]) {
            guard !ids.isEmpty else {
                return
            }

            selectedImages.removeAll { ids.contains($0.id) }
            items.removeAll { ids.contains($0.id) }
        }
    }

#endif
