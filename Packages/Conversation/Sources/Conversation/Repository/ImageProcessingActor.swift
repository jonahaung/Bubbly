//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import MediaPicker
import PhotosUI
import UIKit

actor ImageProcessingActor {

    static let shared = ImageProcessingActor()

    private let cache = NSCache<NSString, UIImage>()

    init() {
        cache.totalCostLimit = 150 * 1024 * 1024 // 150MB
    }

    func process(
        item: SelectedPhotoItem,
        thumbnailSize: CGFloat = 300,
        fullSize: CGFloat = 1600
    ) async -> UIImage? {

        let key = item.id as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let original = UIImage(data: data)
        else { return nil }

        return original
    }

    func removeFromCache(id: String) {
        cache.removeObject(forKey: id as NSString)
    }

    func removeAllFromCache() {
        cache.removeAllObjects()
    }
}
