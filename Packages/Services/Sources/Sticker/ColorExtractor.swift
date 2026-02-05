import Accelerate
import SwiftUI

final class ColorExtractor {
	private let clusterCount = 4
	static let dimension = 256
	static let channelCount = 3
	static let tolerance = 10

	private var sourceImage: CGImage = {
		let buffer = vImage.PixelBuffer(
			pixelValues: [0],
			size: .init(width: 1, height: 1),
			pixelFormat: vImage.Planar8.self
		)

		let fmt = vImage_CGImageFormat(
			bitsPerComponent: 8,
			bitsPerPixel: 8,
			colorSpace: CGColorSpaceCreateDeviceGray(),
			bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
			renderingIntent: .defaultIntent
		)

		return buffer.makeCGImage(cgImageFormat: fmt!)!
	}()

	private var rgbImageFormat = vImage_CGImageFormat(
		bitsPerComponent: 32,
		bitsPerPixel: 32 * 3,
		colorSpace: CGColorSpaceCreateDeviceRGB(),
		bitmapInfo: CGBitmapInfo(
			rawValue: kCGBitmapByteOrder32Host.rawValue |
			CGBitmapInfo.floatComponents.rawValue |
			CGImageAlphaInfo.none.rawValue)
	)!

	private var distances: UnsafeMutableBufferPointer<Float>!

	private let redStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
	private let redBuffer: vImage.PixelBuffer<vImage.PlanarF>

	private let greenStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
	private let greenBuffer: vImage.PixelBuffer<vImage.PlanarF>

	private let blueStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
	private let blueBuffer: vImage.PixelBuffer<vImage.PlanarF>

	private let redQuantizedStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
	private let redQuantizedBuffer: vImage.PixelBuffer<vImage.PlanarF>

	private let greenQuantizedStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
	private let greenQuantizedBuffer: vImage.PixelBuffer<vImage.PlanarF>

	private let blueQuantizedStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
	private let blueQuantizedBuffer: vImage.PixelBuffer<vImage.PlanarF>

	private var centroids = [Centroid]()
	private let centroidIndicesDescriptor: BNNSNDArrayDescriptor

	private let maximumIterations = 50

	init() {
		redBuffer = vImage.PixelBuffer<vImage.PlanarF>(
			data: redStorage.baseAddress!,
			width: ColorExtractor.dimension,
			height: ColorExtractor.dimension,
			byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride
		)

		greenBuffer = vImage.PixelBuffer<vImage.PlanarF>(
			data: greenStorage.baseAddress!,
			width: ColorExtractor.dimension,
			height: ColorExtractor.dimension,
			byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride
		)

		blueBuffer = vImage.PixelBuffer<vImage.PlanarF>(
			data: blueStorage.baseAddress!,
			width: ColorExtractor.dimension,
			height: ColorExtractor.dimension,
			byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride
		)

		redQuantizedBuffer = vImage.PixelBuffer<vImage.PlanarF>(
			data: redQuantizedStorage.baseAddress!,
			width: ColorExtractor.dimension,
			height: ColorExtractor.dimension,
			byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride
		)

		greenQuantizedBuffer = vImage.PixelBuffer<vImage.PlanarF>(
			data: greenQuantizedStorage.baseAddress!,
			width: ColorExtractor.dimension,
			height: ColorExtractor.dimension,
			byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride
		)

		blueQuantizedBuffer = vImage.PixelBuffer<vImage.PlanarF>(
			data: blueQuantizedStorage.baseAddress!,
			width: ColorExtractor.dimension,
			height: ColorExtractor.dimension,
			byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride
		)

		// Each pixel gets an index [0, clusterCount)
		centroidIndicesDescriptor = BNNSNDArrayDescriptor.allocateUninitialized(
			scalarType: Int32.self,
			shape: .vector(ColorExtractor.dimension * ColorExtractor.dimension)
		)

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

	func extractColors(from data: Data) -> PhotoColorScheme? {
		guard let image = cgImage(from: data) else { return nil }

		allocateDistancesBuffer()
		sourceImage = image

		guard let rgbSources: [vImage.PixelBuffer<vImage.PlanarF>] = try? vImage.PixelBuffer<vImage.InterleavedFx3>(
			cgImage: sourceImage,
			cgImageFormat: &rgbImageFormat
		).planarBuffers() else { return nil }

		rgbSources[0].scale(destination: redBuffer)
		rgbSources[1].scale(destination: greenBuffer)
		rgbSources[2].scale(destination: blueBuffer)

		initializeCentroids()

		var converged = false
		var iterationCount = 0

		while !converged, iterationCount < maximumIterations {
			converged = updateCentroids()
			iterationCount += 1
		}

		return .init(colors: centroids.map {
			Color(red: CGFloat($0.red), green: CGFloat($0.green), blue: CGFloat($0.blue))
		})
	}
}

private extension ColorExtractor {
	func allocateDistancesBuffer() {
		distances?.deallocate()
		distances = UnsafeMutableBufferPointer<Float>.allocate(
			capacity: ColorExtractor.dimension * ColorExtractor.dimension * clusterCount
		)
	}

	func cgImage(from data: Data) -> CGImage? {
		guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
			return nil
		}
		return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
	}

	func initializeCentroids() {
		centroids.removeAll()

		let randomIndex = Int.random(in: 0 ..< ColorExtractor.dimension * ColorExtractor.dimension)
		centroids.append(Centroid(
			red: redStorage[randomIndex],
			green: greenStorage[randomIndex],
			blue: blueStorage[randomIndex]
		))

		let temporary = UnsafeMutableBufferPointer(
			start: distances.baseAddress!,
			count: ColorExtractor.dimension * ColorExtractor.dimension
		)

		for centroidIndex in 1 ..< clusterCount {
			distanceSquared(
				greenPointer: greenStorage.baseAddress!, greenValue: centroids[centroidIndex - 1].green,
				bluePointer: blueStorage.baseAddress!, blueValue: centroids[centroidIndex - 1].blue,
				redPointer: redStorage.baseAddress!, redValue: centroids[centroidIndex - 1].red,
				count: greenStorage.count,
				result: temporary.baseAddress!
			)

			let nextRandomIndex = weightedRandomIndex(temporary)
			centroids.append(Centroid(
				red: redStorage[nextRandomIndex],
				green: greenStorage[nextRandomIndex],
				blue: blueStorage[nextRandomIndex]
			))
		}
	}

	func updateCentroids() -> Bool {
		let previousPixelCounts = centroids.map(\.pixelCount)
		populateDistances()
		guard let centroidIndices = makeCentroidIndices() else { return false }

		for centroid in centroids.enumerated() {
			let indices = centroidIndices.enumerated().filter {
				$0.element == centroid.offset
			}.map {
				UInt($0.offset + 1)
			}

			centroids[centroid.offset].pixelCount = indices.count

			if !indices.isEmpty {
				let gatheredRed = vDSP.gather(redStorage, indices: indices)
				let gatheredGreen = vDSP.gather(greenStorage, indices: indices)
				let gatheredBlue = vDSP.gather(blueStorage, indices: indices)

				centroids[centroid.offset].red = vDSP.mean(gatheredRed)
				centroids[centroid.offset].green = vDSP.mean(gatheredGreen)
				centroids[centroid.offset].blue = vDSP.mean(gatheredBlue)
			}
		}

		return previousPixelCounts.elementsEqual(centroids.map(\.pixelCount)) { lhs, rhs in
			abs(lhs - rhs) < ColorExtractor.tolerance
		}
	}

	func populateDistances() {
		for centroid in centroids.enumerated() {
			distanceSquared(
				greenPointer: greenStorage.baseAddress!, greenValue: centroid.element.green,
				bluePointer: blueStorage.baseAddress!, blueValue: centroid.element.blue,
				redPointer: redStorage.baseAddress!, redValue: centroid.element.red,
				count: greenStorage.count,
				result: distances.baseAddress!.advanced(
					by: ColorExtractor.dimension * ColorExtractor.dimension * centroid.offset
				)
			)
		}
	}

	func makeCentroidIndices() -> [Int32]? {
		guard let distancesDescriptor = BNNSNDArrayDescriptor(
			data: distances,
			shape: .matrixRowMajor(ColorExtractor.dimension * ColorExtractor.dimension, clusterCount)
		) else { return nil }

		do {
			try BNNS.applyReduction(
				.argMin,
				input: distancesDescriptor,
				output: centroidIndicesDescriptor,
				weights: nil
			)
			return centroidIndicesDescriptor.makeArray(of: Int32.self)
		} catch {
			return nil
		}
	}

	func weightedRandomIndex(_ weights: UnsafeMutableBufferPointer<Float>) -> Int {
		var outputDescriptor = BNNSNDArrayDescriptor.allocateUninitialized(
			scalarType: Float.self,
			shape: .vector(1)
		)

		var probabilities = BNNSNDArrayDescriptor(
			data: weights,
			shape: .vector(weights.count)
		)!

		let randomGenerator = BNNSCreateRandomGenerator(BNNSRandomGeneratorMethodAES_CTR, nil)
		BNNSRandomFillCategoricalFloat(randomGenerator, &outputDescriptor, &probabilities, false)

		let result = Int(outputDescriptor.makeArray(of: Float.self)!.first!)
		BNNSDestroyRandomGenerator(randomGenerator)
		outputDescriptor.deallocate()

		return result
	}

	private func distanceSquared(
		greenPointer: UnsafePointer<Float>, greenValue: Float,
		bluePointer: UnsafePointer<Float>, blueValue: Float,
		redPointer: UnsafePointer<Float>, redValue: Float,
		count: Int,
		result: UnsafeMutablePointer<Float>
	) {
		var green = subtract(a: greenPointer, b: greenValue, n: count)
		vDSP.square(green, result: &green)

		var blue = subtract(a: bluePointer, b: blueValue, n: count)
		vDSP.square(blue, result: &blue)

		var red = subtract(a: redPointer, b: redValue, n: count)
		vDSP.square(red, result: &red)

		vDSP_vadd(green, 1, blue, 1, result, 1, vDSP_Length(count))
		vDSP_vadd(result, 1, red, 1, result, 1, vDSP_Length(count))
	}

	func subtract(a: UnsafePointer<Float>, b: Float, n: Int) -> [Float] {
		[Float](unsafeUninitializedCapacity: n) { buffer, count in
			vDSP_vsub(a, 1, [b], 0, buffer.baseAddress!, 1, vDSP_Length(n))
			count = n
		}
	}

	func saturate<T: FloatingPoint>(_ value: T) -> T {
		min(max(0, value), 1)
	}
}

private extension ColorExtractor {
	struct Centroid {
		var red: Float
		var green: Float
		var blue: Float
		var pixelCount: Int = 0
	}
}
