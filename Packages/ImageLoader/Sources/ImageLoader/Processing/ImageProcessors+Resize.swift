// The MIT License (MIT)
//
// Copyright (c) 2015-2024 Alexander Grebenyuk (github.com/kean).

import Foundation
import CoreGraphics
import SwiftUI
import PhotosUI
import Vision
import CoreImage.CIFilterBuiltins
import Accelerate
import simd
import SwiftUI
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

extension ImageProcessors {
	public struct Sticker: ImageProcessing, Hashable, CustomStringConvertible {
		public func process(_ image: PlatformImage) -> PlatformImage? {
			guard let data = image.pngData() else { return nil }
			if let pngData = try? extractSticker(from: data).pngData() {
//				let colors = ColorExtractor().extractColors(from: data)
//				if let platformImage = PlatformImage(data: pngData) {
//					if let color = colors?.colors.first {
//						if let cgImage = platformImage.cgImage {
//							let radius = CGFloat(cgImage.width)/2
//							return platformImage.processed.byAddingRoundedCorners(radius: radius, backgroundColor: color)
//						}
//					}
//					return .init(data: pngData)
//				}
				return .init(data: pngData)
			}
			return .init(data: data)
		}
		public var identifier: String {
			"Sticker"
		}

		public var description: String {
			"Sticker"
		}

		public func extractSticker(from data: Data) throws -> UIImage {
			guard let uiImage = UIImage(data: data) else { fatalError("Failed to create UIImage from data") }
			guard let image = CIImage(data: data) else { return uiImage }

			let handler = VNImageRequestHandler(ciImage: image)
			let request = VNGenerateForegroundInstanceMaskRequest()

			try handler.perform([request])

			guard let result = request.results?.first else { return uiImage }


			let maskPixelBuffer = try result.generateScaledMaskForImage(
				forInstances: IndexSet(result.allInstances.filter{ $0 != 0 }),
				from: handler
			)
			let mask = CIImage(cvPixelBuffer: maskPixelBuffer)
			let extent = mask.extent

			let minDimension = min(extent.width, extent.height)
			let scaledRadius = max(1, Int(minDimension * 0.02))

			let dilatedMask = mask
				.applyingFilter("CIMorphologyMaximum", parameters: [
					"inputRadius": scaledRadius
				])

			let whiteBackground = CIImage(color: .white)
				.cropped(to: extent)
				.applyingFilter("CIBlendWithMask", parameters: [
					"inputMaskImage": dilatedMask
				])

			let subject = image
				.applyingFilter("CIBlendWithMask", parameters: [
					"inputMaskImage": mask
				])
			let sticker = subject.composited(over: whiteBackground)
			guard let cgImage = CIContext()
				.createCGImage(sticker, from: sticker.extent) else {
				return uiImage
			}
			return UIImage(cgImage: cgImage, scale: 1, orientation: uiImage.imageOrientation)
		}
	}

}
final class ColorExtractor {
	public struct PhotoColorScheme: @unchecked Sendable {
		public let colors: [Color]

		public init(colors: [Color]) {
			self.colors = colors
		}
	}


	private let k = 4

	static let dimension = 256
	static let channelCount = 3
	static let tolerance = 10

	/// The current source image.
	private var sourceImage: CGImage = {
		let buffer = vImage.PixelBuffer(
			pixelValues: [0],
			size: .init(width: 1, height: 1),
			pixelFormat: vImage.Planar8.self)

		let fmt = vImage_CGImageFormat(
			bitsPerComponent: 8,
			bitsPerPixel: 8 ,
			colorSpace: CGColorSpaceCreateDeviceGray(),
			bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
			renderingIntent: .defaultIntent)

		return buffer.makeCGImage(cgImageFormat: fmt!)!
	}()

	/// The Core Graphics image format.
	private var rgbImageFormat = vImage_CGImageFormat(
		bitsPerComponent: 32,
		bitsPerPixel: 32 * 3,
		colorSpace: CGColorSpaceCreateDeviceRGB(),
		bitmapInfo: CGBitmapInfo(
			rawValue: kCGBitmapByteOrder32Host.rawValue |
			CGBitmapInfo.floatComponents.rawValue |
			CGImageAlphaInfo.none.rawValue))!

	/// Storage for a matrix with `dimension * dimension` columns and `k` rows that stores the
	/// distances squared of each pixel color for each centroid.
	private var distances: UnsafeMutableBufferPointer<Float>!

	/// The storage and pixel buffer for each red value.
	private let redStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
	private let redBuffer: vImage.PixelBuffer<vImage.PlanarF>

	/// The storage and pixel buffer for each green value.
	private let greenStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
	private let greenBuffer: vImage.PixelBuffer<vImage.PlanarF>

	/// The storage and pixel buffer for each blue value.
	private let blueStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
	private let blueBuffer: vImage.PixelBuffer<vImage.PlanarF>

	/// The storage and pixel buffer for each quantized red value.
	private let redQuantizedStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
	private let redQuantizedBuffer: vImage.PixelBuffer<vImage.PlanarF>

	/// The storage and pixel buffer for each quantized green value.
	private let greenQuantizedStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
	private let greenQuantizedBuffer: vImage.PixelBuffer<vImage.PlanarF>

	/// The storage and pixel buffer for each quantized blue value.
	private let blueQuantizedStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
	private let blueQuantizedBuffer: vImage.PixelBuffer<vImage.PlanarF>

	/// The array of `k` centroids.
	private var centroids = [Centroid]()

	/// The BNNS array descriptor that receives the centroid indices.
	private let centroidIndicesDescriptor: BNNSNDArrayDescriptor

	private let maximumIterations = 50
	private var iterationCount = 0

	/// - Tag: Life cycle
	init() {
		redBuffer = vImage.PixelBuffer<vImage.PlanarF>(
			data: redStorage.baseAddress!,
			width: ColorExtractor.dimension,
			height: ColorExtractor.dimension,
			byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride)

		greenBuffer = vImage.PixelBuffer<vImage.PlanarF>(
			data: greenStorage.baseAddress!,
			width: ColorExtractor.dimension,
			height: ColorExtractor.dimension,
			byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride)

		blueBuffer = vImage.PixelBuffer<vImage.PlanarF>(
			data: blueStorage.baseAddress!,
			width: ColorExtractor.dimension,
			height: ColorExtractor.dimension,
			byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride)

		redQuantizedBuffer = vImage.PixelBuffer<vImage.PlanarF>(
			data: redQuantizedStorage.baseAddress!,
			width: ColorExtractor.dimension,
			height: ColorExtractor.dimension,
			byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride)

		greenQuantizedBuffer = vImage.PixelBuffer<vImage.PlanarF>(
			data: greenQuantizedStorage.baseAddress!,
			width: ColorExtractor.dimension,
			height: ColorExtractor.dimension,
			byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride)

		blueQuantizedBuffer = vImage.PixelBuffer<vImage.PlanarF>(
			data: blueQuantizedStorage.baseAddress!,
			width: ColorExtractor.dimension,
			height: ColorExtractor.dimension,
			byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride)

		centroidIndicesDescriptor = BNNSNDArrayDescriptor.allocateUninitialized(
			scalarType: Int32.self,
			shape: .matrixRowMajor(ColorExtractor.dimension * ColorExtractor.dimension, 1))

		allocateDistancesBuffer()
	}

	deinit {
		redStorage.deallocate()
		greenStorage.deallocate()
		blueStorage.deallocate()

		redQuantizedStorage.deallocate()
		greenQuantizedStorage.deallocate()
		blueQuantizedStorage.deallocate()

		centroidIndicesDescriptor.deallocate()
		distances.deallocate()
	}

	/// Calculates k-means for the selected thumbnail.
	func extractColors(from data: Data) -> PhotoColorScheme? {
		guard let image = cgImage(from: data) else { return nil }

		allocateDistancesBuffer()
		sourceImage = image

		let rgbSources: [vImage.PixelBuffer<vImage.PlanarF>] = try! vImage.PixelBuffer<vImage.InterleavedFx3>(
			cgImage: sourceImage,
			cgImageFormat: &rgbImageFormat).planarBuffers()

		rgbSources[0].scale(destination: redBuffer)
		rgbSources[1].scale(destination: greenBuffer)
		rgbSources[2].scale(destination: blueBuffer)

		initializeCentroids()

		var converged = false
		var iterationCount = 0

		while !converged && iterationCount < maximumIterations {
			converged = updateCentroids()
			iterationCount += 1
		}

		return .init(colors: centroids.map {
			Color(red: CGFloat($0.red), green: CGFloat($0.green), blue: CGFloat($0.blue), alpha: 1)
		})
	}
}

private nonisolated extension ColorExtractor {
	/// Allocates the memory required for the distances matrix.
	func allocateDistancesBuffer() {
		if distances != nil {
			distances.deallocate()
		}
		distances = UnsafeMutableBufferPointer<Float>.allocate(capacity: ColorExtractor.dimension * ColorExtractor.dimension * k)
	}

	func cgImage(from data: Data) -> CGImage? {
		guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
			return nil
		}

		return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
	}

	/// - Tag: initializeCentroids
	func initializeCentroids() {
		centroids.removeAll()

		let randomIndex = Int.random(in: 0 ..< ColorExtractor.dimension * ColorExtractor.dimension)
		centroids.append(Centroid(red: redStorage[randomIndex],
								  green: greenStorage[randomIndex],
								  blue: blueStorage[randomIndex]))

		// Use the first row of the `distances` buffer as temporary storage.
		let tmp = UnsafeMutableBufferPointer(start: distances.baseAddress!,
											 count: ColorExtractor.dimension * ColorExtractor.dimension)
		for i in 1 ..< k {
			distanceSquared(x0: greenStorage.baseAddress!, x1: centroids[i - 1].green,
							y0: blueStorage.baseAddress!, y1: centroids[i - 1].blue,
							z0: redStorage.baseAddress!, z1: centroids[i - 1].red,
							n: greenStorage.count,
							result: tmp.baseAddress!)

			let randomIndex = weightedRandomIndex(tmp)

			centroids.append(Centroid(red: redStorage[randomIndex],
									  green: greenStorage[randomIndex],
									  blue: blueStorage[randomIndex]))
		}
	}

	/// Updates centroids and returns `true` when the pixel counts don't change
	/// (that is, the solution converges).
	///
	/// 1. Create k random centroids that the system selects from the RGB colors in an image.
	/// 2. Create a distances matrix that has pixel-count columns and k rows.
	/// 3. For each centroid, populate the corresponding row in the distances matrix with the distance squared
	/// between it and each matrix.
	/// 4. Use the BNNS reduction `argMin` on the distances matrix to create a vector with pixel-count elements.
	/// Each element in the vector is the centroid that's the closest color to the corresponding pixel.
	/// 5. For each centroid, use BNNS gather to create a vector for each RGB channel of the pixel
	/// colors for that centroid. Compute the mean value of that vector and set the centroid color to that average.
	/// 6. Repeat steps 3, 4, and 5 until the solution converges.
	/// - Tag: updateCentroids
	func updateCentroids() -> Bool {
		// The pixel counts per centroid before this iteration.
		let pixelCounts = centroids.map { return $0.pixelCount }

		populateDistances()
		let centroidIndices = makeCentroidIndices()

		for centroid in centroids.enumerated() {

			// The indices into the red, green, and blue descriptors for this centroid.
			let indices = centroidIndices.enumerated().filter {
				$0.element == centroid.offset
			}.map {
				// `vDSP.gather` uses one-based indices.
				UInt($0.offset + 1)
			}

			centroids[centroid.offset].pixelCount = indices.count

			if !indices.isEmpty {
				let gatheredRed = vDSP.gather(redStorage,
											  indices: indices)

				let gatheredGreen = vDSP.gather(greenStorage,
												indices: indices)

				let gatheredBlue = vDSP.gather(blueStorage,
											   indices: indices)

				centroids[centroid.offset].red = vDSP.mean(gatheredRed)
				centroids[centroid.offset].green = vDSP.mean(gatheredGreen)
				centroids[centroid.offset].blue = vDSP.mean(gatheredBlue)
			}
		}

		return pixelCounts.elementsEqual(centroids.map { return $0.pixelCount }) { a, b in
			return abs(a - b) < ColorExtractor.tolerance
		}
	}

	func populateDistances() {
		for centroid in centroids.enumerated() {
			distanceSquared(x0: greenStorage.baseAddress!, x1: centroid.element.green,
							y0: blueStorage.baseAddress!, y1: centroid.element.blue,
							z0: redStorage.baseAddress!, z1: centroid.element.red,
							n: greenStorage.count,
							result: distances.baseAddress!.advanced(by: ColorExtractor.dimension * ColorExtractor.dimension * centroid.offset))
		}
	}

	/// Returns the index of the closest centroid for each color.
	func makeCentroidIndices() -> [Int32] {
		let distancesDescriptor = BNNSNDArrayDescriptor(
			data: distances,
			shape: .matrixRowMajor(ColorExtractor.dimension * ColorExtractor.dimension, k))!

		try! BNNS.applyReduction(.argMin, input: distancesDescriptor, output: centroidIndicesDescriptor, weights: nil)

		return centroidIndicesDescriptor.makeArray(of: Int32.self)!
	}

	func weightedRandomIndex(_ weights: UnsafeMutableBufferPointer<Float>) -> Int {
		var outputDescriptor = BNNSNDArrayDescriptor.allocateUninitialized(
			scalarType: Float.self,
			shape: .vector(1))

		var probabilities = BNNSNDArrayDescriptor(
			data: weights,
			shape: .vector(weights.count))!

		let randomGenerator = BNNSCreateRandomGenerator(
			BNNSRandomGeneratorMethodAES_CTR,
			nil)

		BNNSRandomFillCategoricalFloat(
			randomGenerator, &outputDescriptor, &probabilities, false)

		let result = Int(outputDescriptor.makeArray(of: Float.self)!.first!)
		BNNSDestroyRandomGenerator(randomGenerator)
		outputDescriptor.deallocate()

		return result
	}

	private func distanceSquared(
		x0: UnsafePointer<Float>, x1: Float,
		y0: UnsafePointer<Float>, y1: Float,
		z0: UnsafePointer<Float>, z1: Float,
		n: Int,
		result: UnsafeMutablePointer<Float>
	) {
		var x = subtract(a: x0, b: x1, n: n)
		vDSP.square(x, result: &x)

		var y = subtract(a: y0, b: y1, n: n)
		vDSP.square(y, result: &y)

		var z = subtract(a: z0, b: z1, n: n)
		vDSP.square(z, result: &z)

		vDSP_vadd(x, 1, y, 1, result, 1, vDSP_Length(n))
		vDSP_vadd(result, 1, z, 1, result, 1, vDSP_Length(n))
	}

	func subtract(a: UnsafePointer<Float>, b: Float, n: Int) -> [Float] {
		return [Float](unsafeUninitializedCapacity: n) {
			buffer, count in

			vDSP_vsub(a, 1,
					  [b], 0,
					  buffer.baseAddress!, 1,
					  vDSP_Length(n))

			count = n
		}
	}

	func saturate<T: FloatingPoint>(_ x: T) -> T {
		min(max(0, x), 1)
	}
}

/// - Tag: Centroid
private extension ColorExtractor {
	/// A structure that represents a centroid.
	struct Centroid {
		/// The red channel value.
		var red: Float

		/// The green channel value.
		var green: Float

		/// The blue channel value.
		var blue: Float

		/// The number of assigned pixels for this cluster center.
		var pixelCount: Int = 0
	}
}
