import Foundation
import UIKit

// MARK: - MediaManager Class

public final class MediaManager: Sendable {
	public static let shared = MediaManager()

	private init() {}

	public func createThumbnail(from uiImage: UIImage) async throws -> Data {
		guard let data = uiImage.resized(toWidth: 100)?.pngData() else {
			throw NSError(domain: "Falied to create thumbnil", code: 0)
		}
		return data
	}

	public func createData(from uiImage: UIImage) throws -> Data {
		guard let data = uiImage.pngData() else {
			throw NSError(domain: "Falied to create data", code: 0)
		}
		return data
	}
}
