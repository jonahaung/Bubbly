//  CameraPickerItem.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI
import AVFoundation

public protocol CameraPickerItem: Identifiable where ID == UUID {
    associatedtype MediaType

    var mediaType: MediaType { get }
    var id: Self.ID { get }

    func save() async throws
}

public struct ImageCameraPickerItem: CameraPickerItem {
    public let id: UUID = .init()
    public var mediaType: Image
    public var underlyingMediaType: UIImage

    public func save() async throws {
        let mediaSaver = MediaSaver()
        try await mediaSaver.save(underlyingMediaType)
    }
}

public struct MovieCameraPickerItem: CameraPickerItem {
    public let id: UUID = .init()
    public var mediaType: AVPlayer
    var underlyingMediaType: URL

    public func save() async throws {
        let mediaSaver = MediaSaver()
        try await mediaSaver.saveMovie(at: underlyingMediaType)
    }
}
