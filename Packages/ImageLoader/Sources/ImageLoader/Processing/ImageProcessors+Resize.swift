// The MIT License (MIT)
//
// Copyright (c) 2015-2024 Alexander Grebenyuk (github.com/kean).

import Foundation
import CoreGraphics

#if !os(macOS)
import UIKit
#else
import AppKit
#endif

extension ImageProcessors {

	public struct Resize: ImageProcessing, Hashable, CustomStringConvertible {
		private let size: ImageTargetSize
		private let contentMode: ImageProcessingOptions.ContentMode
		private let crop: Bool
		private let upscale: Bool

		public typealias ContentMode = ImageProcessingOptions.ContentMode

		public init(
			size: CGSize,
			unit: ImageProcessingOptions.Unit = .points,
			contentMode: ImageProcessingOptions.ContentMode = .aspectFill,
			crop: Bool = true,
			upscale: Bool = true
		) {
			self.size = ImageTargetSize(size: size, unit: unit)
			self.contentMode = contentMode
			self.crop = crop
			self.upscale = upscale
		}

		public init(
			width: CGFloat,
			unit: ImageProcessingOptions.Unit = .points,
			upscale: Bool = true
		) {
			self.init(
				size: CGSize(width: width, height: 9999),
				unit: unit,
				contentMode: .aspectFit,
				crop: true,
				upscale: upscale
			)
		}

		public init(
			height: CGFloat,
			unit: ImageProcessingOptions.Unit = .points,
			upscale: Bool = true
		) {
			self.init(
				size: CGSize(width: 9999, height: height),
				unit: unit,
				contentMode: .aspectFit,
				crop: true,
				upscale: upscale
			)
		}

		public func process(_ image: PlatformImage) -> PlatformImage? {
			if crop && contentMode == .aspectFill {
				return image.processed.byResizingAndCropping(to: size.cgSize)
			}
			return image.processed.byResizing(to: size.cgSize, contentMode: contentMode, upscale: upscale)
		}

		public var identifier: String {
			"com.github.kean/nuke/resize?s=\(size.cgSize),cm=\(contentMode),crop=\(crop),upscale=\(upscale)"
		}

		public var description: String {
			"Resize(size: \(size.cgSize) pixels, contentMode: \(contentMode), crop: \(crop), upscale: \(upscale))"
		}
	}
}

struct ImageTargetSize: Hashable {
	let cgSize: CGSize
	init(size: CGSize, unit: ImageProcessingOptions.Unit) {
		switch unit {
		case .pixels: self.cgSize = size // The size is already in pixels
		case .points: self.cgSize = size.scaled(by: Screen.scale)
		}
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(cgSize.width)
		hasher.combine(cgSize.height)
	}
}
