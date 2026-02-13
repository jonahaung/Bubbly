import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI
import Vision

public nonisolated struct StickerProcessor: Sendable {
	public enum ExtractionError: Error {
		case ciImageCreationFailed
		case requestFailed
		case cgImageCreationFailed
	}

	public init() {}

	@concurrent
	public func process(data: Data) async throws -> Sticker {
		async let sticker = extractSticker(from: data)
		async let colors = extractColors(from: data)
		let value = try await sticker
		return await Sticker(sticker: value, colorScheme: colors)
	}

	public func extractColors(from data: Data) -> PhotoColorScheme {
		let colorExtractor = ColorExtractor()
		return colorExtractor.extractColors(from: data) ?? .init(colors: [])
	}

	public func extractSticker(from data: Data) throws -> UIImage {
		guard let uiImage = UIImage(data: data)
		else { fatalError("Failed to create UIImage from data") }
		guard let image = CIImage(data: data) else { return uiImage }

		let handler = VNImageRequestHandler(ciImage: image)
		let request = VNGenerateForegroundInstanceMaskRequest()

		try handler.perform([request])

		guard let result = request.results?.first else { return uiImage }

		let maskPixelBuffer = try result.generateScaledMaskForImage(
			forInstances: IndexSet(result.allInstances.filter { $0 != 0 }),
			from: handler
		)
		let mask = CIImage(cvPixelBuffer: maskPixelBuffer)
		let extent = mask.extent

		let minDimension = min(extent.width, extent.height)
		let scaledRadius = max(1, Int(minDimension * 0.02))

		let dilatedMask = mask
			.applyingFilter("CIMorphologyMaximum", parameters: [
				"inputRadius": scaledRadius,
			])

		let whiteBackground = CIImage(color: .white)
			.cropped(to: extent)
			.applyingFilter("CIBlendWithMask", parameters: [
				"inputMaskImage": dilatedMask,
			])

		let subject = image
			.applyingFilter("CIBlendWithMask", parameters: [
				"inputMaskImage": mask,
			])

		let sticker = subject.composited(over: whiteBackground)
		guard let cgImage = CIContext()
			.createCGImage(sticker, from: sticker.extent)
		else {
			return uiImage
		}
		return UIImage(cgImage: cgImage, scale: 0.5, orientation: uiImage.imageOrientation)
	}
}
