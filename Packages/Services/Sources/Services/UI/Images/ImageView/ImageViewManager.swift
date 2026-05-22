// © 2026 Aung Ko Min

import Database
import ImageLoader
import SwiftUI
import XUI

@MainActor
@Observable
final class ImageViewManager {
    
    let item: any ImageViewItem
    var image: UIImage? = nil
    var progress: ImageTask.Progress? = nil

    init(item: any ImageViewItem) {
        self.item = item
    }

    func isLocallyCached() -> Bool {
        item.fileExist()
    }

    func loadLocalImage(isThumbnil: Bool) {
        guard image == nil else {
            return
        }

        guard isLocallyCached() else {
            return
        }

        if isThumbnil {
            image = item.thumbnailImage()
        } else {
            image = item.image()
        }
    }

    func onCompletion(_ result: Result<ImageResponse, Error>) {
        switch result {
        case let .success(success):
            Task {
                do {
                    try await self.saveImage(success.image)
					loadLocalImage(isThumbnil: true)
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
        item.remoteURL
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
