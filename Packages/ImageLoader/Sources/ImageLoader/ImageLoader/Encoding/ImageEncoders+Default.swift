//
//  ImageLoader.swift
//
//
//  Created by Aung Ko Min on 29/6/24.
//
import Foundation

#if !os(macOS)
	import UIKit
#else
	import AppKit
#endif

public extension ImageEncoders {
	/// A default adaptive encoder which uses best encoder available depending
	/// on the input image and its configuration.
	struct Default: ImageEncoding {
		public var compressionQuality: Float

		/// Set to `true` to switch to HEIF when it is available on the current hardware.
		/// `false` by default.
		public var isHEIFPreferred = false

		public init(compressionQuality: Float = 0.8) {
			self.compressionQuality = compressionQuality
		}

		public func encode(_ image: PlatformImage) -> Data? {
			guard let cgImage = image.cgImage else {
				return nil
			}
			let type: AssetType = if cgImage.isOpaque {
				if isHEIFPreferred, ImageEncoders.ImageIO.isSupported(type: .heic) {
					.heic
				} else {
					.jpeg
				}
			} else {
				.png
			}
			let encoder = ImageEncoders.ImageIO(type: type, compressionRatio: compressionQuality)
			return encoder.encode(image)
		}
	}
}
