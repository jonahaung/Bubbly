//  MediaSaver.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import UIKit

final class MediaSaver: NSObject {
    typealias SaveImageContinuation = CheckedContinuation<Void, Error>
    typealias SaveMovieContinuation = CheckedContinuation<Void, Error>

    var saveImageContinuation: SaveImageContinuation?
    var saveMovieContinuation: SaveMovieContinuation?

    func save(_ image: UIImage) async throws {
        try await withCheckedThrowingContinuation { (continuation: SaveImageContinuation) in
            self.saveImageContinuation = continuation

            UIImageWriteToSavedPhotosAlbum(
                image,
                self,
                #selector(image(_:didFinishSavingWithError:contextInfo:)),
                nil
            )
        }
    }

    func saveMovie(at url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: SaveMovieContinuation) in
            self.saveMovieContinuation = continuation

            let path: String = if #available(iOS 16, *) {
                url.path()
            } else {
                url.path
            }

            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path) {
                UISaveVideoAtPathToSavedPhotosAlbum(
                    path,
                    self,
                    #selector(video(_:didFinishSavingWithError:contextInfo:)),
                    nil
                )
            }
        }
    }

    @objc func image(
        _: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo _: UnsafeRawPointer
    ) {
        if let error {
            saveImageContinuation?.resume(throwing: error)
        } else {
            saveImageContinuation?.resume()
        }

        saveImageContinuation = nil
    }

    @objc func video(
        _: String?,
        didFinishSavingWithError error: Error?,
        contextInfo _: UnsafeMutableRawPointer?
    ) {
        if let error {
            saveMovieContinuation?.resume(throwing: error)
        } else {
            saveMovieContinuation?.resume()
        }

        saveMovieContinuation = nil
    }
}
