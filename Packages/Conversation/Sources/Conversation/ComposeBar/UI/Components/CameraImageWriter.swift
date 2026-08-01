import Foundation
import SwiftUI

actor CameraImageWriter {
    private let maximumDimension: CGFloat = 2_048
    private let compressionQuality = 0.85

    func write(_ image: UIImage) throws -> URL {
        try Task.checkCancellation()
        let preparedImage = resizedImage(from: image)
        guard let data = preparedImage.jpegData(compressionQuality: compressionQuality) else {
            throw CocoaError(.fileWriteUnknown)
        }

        try Task.checkCancellation()
        let url = URL.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("jpg")
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            try Task.checkCancellation()
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
        return url
    }

    func removeFiles(at urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func resizedImage(from image: UIImage) -> UIImage {
        let largestDimension = max(image.size.width, image.size.height)
        guard largestDimension > maximumDimension else {
            return image
        }

        let scale = maximumDimension / largestDimension
        let size = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
