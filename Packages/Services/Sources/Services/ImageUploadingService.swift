// © 2026 Aung Ko Min

import Database
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import XUI

public struct ImageUploadingService: Sendable {
    public enum Path {
        case user(uid: String)
        case group(groupID: String)
        case conversation(conID: String, attachmentID: String)

        var backendPath: BackendAPIClient.MediaPath? {
            switch self {
            case .user:
                nil
            case let .group(groupID):
                .group(groupID: groupID)
            case let .conversation(conID, attachmentID):
                .conversation(conversationID: conID, attachmentID: attachmentID)
            }
        }
    }

    public init() {}

    public func uploadImage(
        _ image: UIImage,
        size: CGSize?,
        to path: Path,
        onProgress: (@Sendable (Progress?) -> Void)? = nil,
    ) async throws
        -> URL
    {
        let mediaManager = MediaManager.shared

        let uploadingImage: UIImage =
            if let size, let resizedImage = image.resizedToFill(size) {
                resizedImage
            } else {
                image
            }
        let data = try mediaManager.createData(from: uploadingImage)

        if case .user = path {
            return try await BackendAPIClient.shared.uploadProfilePhoto(
                data: data,
                contentType: "image/png"
            )
        }

        guard let backendPath = path.backendPath else {
            throw ImageUploadingError.invalidPath
        }
        let progress = Progress(totalUnitCount: Int64(data.count))
        onProgress?(progress)
        let url = try await BackendAPIClient.shared.uploadMedia(
            data: data,
            contentType: "image/png",
            to: backendPath
        )
        progress.completedUnitCount = progress.totalUnitCount
        onProgress?(progress)
        return url
    }

    public func uploadFile(
        _ url: URL,
        to path: Path,
        onProgress: (@Sendable (Progress?) -> Void)? = nil,
    ) async throws -> URL {
        if case .user = path {
            return try await BackendAPIClient.shared.uploadProfilePhoto(
                fileURL: url,
                contentType: "image/jpeg"
            )
        }
        guard let backendPath = path.backendPath else {
            throw ImageUploadingError.invalidPath
        }
        let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        let progress = Progress(totalUnitCount: Int64(fileSize))
        onProgress?(progress)
        let uploadedURL = try await BackendAPIClient.shared.uploadMedia(
            fileURL: url,
            contentType: "image/jpeg",
            to: backendPath
        )
        progress.completedUnitCount = progress.totalUnitCount
        onProgress?(progress)
        return uploadedURL
    }
}

private enum ImageUploadingError: Error {
    case invalidPath
}

public extension UIImage {
    func resizedToFit(in targetSize: CGSize) -> UIImage? {
        let aspectRatio = min(
            targetSize.width / size.width,
            targetSize.height / size.height,
        )

        let newSize = CGSize(
            width: size.width * aspectRatio,
            height: size.height * aspectRatio,
        )

        return renderResizedImage(to: newSize)
    }

    func resizedToFill(_ targetSize: CGSize) -> UIImage? {
        let aspectRatio = max(
            targetSize.width / size.width,
            targetSize.height / size.height,
        )

        let scaledSize = CGSize(
            width: size.width * aspectRatio,
            height: size.height * aspectRatio,
        )

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            let origin = CGPoint(
                x: (targetSize.width - scaledSize.width) * 0.5,
                y: (targetSize.height - scaledSize.height) * 0.5,
            )
            draw(in: CGRect(origin: origin, size: scaledSize))
        }
    }

    func resized(toWidth width: CGFloat) -> UIImage? {
        let scale = width / size.width
        let newHeight = size.height * scale
        let newSize = CGSize(width: width, height: newHeight)
        return renderResizedImage(to: newSize)
    }

    private func renderResizedImage(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
