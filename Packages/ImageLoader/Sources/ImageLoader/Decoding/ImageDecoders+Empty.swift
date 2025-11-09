//
//  ImageLoader.swift
//
//
//  Created by Aung Ko Min on 29/6/24.
//
import Foundation

public extension ImageDecoders {
    /// A decoder that returns an empty placeholder image and attaches image
    /// data to the image container.
    struct Empty: ImageDecoding, Sendable {
        public let isProgressive: Bool
        private let assetType: AssetType?

        public var isAsynchronous: Bool { false }

        /// Initializes the decoder.
        ///
        /// - Parameters:
        ///   - type: Image type to be associated with an image container.
        ///   `nil` by default.
        ///   - isProgressive: If `false`, returns nil for every progressive
        ///   scan. `false` by default.
        public init(assetType: AssetType? = nil, isProgressive: Bool = false) {
            self.assetType = assetType
            self.isProgressive = isProgressive
        }

        public func decode(_ data: Data) throws -> ImageContainer {
            ImageContainer(image: PlatformImage(), type: assetType, data: data, userInfo: [:])
        }

        public func decodePartiallyDownloadedData(_ data: Data) -> ImageContainer? {
            isProgressive ? ImageContainer(image: PlatformImage(), type: assetType, data: data, userInfo: [:]) : nil
        }
    }
}
