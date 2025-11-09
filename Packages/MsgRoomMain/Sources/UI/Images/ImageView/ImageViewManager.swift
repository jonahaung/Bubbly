//
//  ImageViewManager.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 4/9/25.
//

import Database
import ImageLoader
import Services
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
                    Log(error)
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
