//
//  PhotoPicker.swift
//  PHPickerDemo
//
//  Created by Gabriel Theodoropoulos.
//

@preconcurrency import SwiftUI
import PhotosUI
import AVKit

public struct PhotoPicker: UIViewControllerRepresentable {

	@Binding public var attachments: [XAttachment]
	public var multipleSelection: Bool
	private var filter: PHPickerFilter? = .any(of: [.images, .screenshots])
	private var preferredAssetRepresentationMode: PHPickerConfiguration.AssetRepresentationMode = .compatible
	private var preselectedAssetIdentifiers: [String] = []
	private var selectionLimit: Int = 1
	private var selection: PHPickerConfiguration.Selection = .default
	private let photoLibrary: PHPhotoLibrary = .shared()

	public init(attachments: Binding<[XAttachment]>, multipleSelection: Bool, filter: PHPickerFilter? = nil) {
		_attachments = attachments
		self.multipleSelection = multipleSelection
	}

	public func makeUIViewController(context: Context) -> PHPickerViewController {
		var config = PHPickerConfiguration(photoLibrary: photoLibrary)
		config.filter = filter
		config.preferredAssetRepresentationMode = preferredAssetRepresentationMode
		config.preselectedAssetIdentifiers = preselectedAssetIdentifiers
		config.selectionLimit = selectionLimit
		config.selection = selection
		let picker = PHPickerViewController(configuration: config)
		picker.extendedLayoutIncludesOpaqueBars = true
		picker.edgesForExtendedLayout = .all
		picker.delegate = context.coordinator
		picker.edgesForExtendedLayout = .all
		let controller = PHPickerViewController(configuration: config)
		controller.delegate = context.coordinator
		return controller
	}

	public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

	public func makeCoordinator() -> Coordinator {
		return Coordinator(self)
	}

	public class Coordinator: NSObject, PHPickerViewControllerDelegate, UINavigationControllerDelegate {
		let parent: PhotoPicker

		init(_ parent: PhotoPicker) {
			self.parent = parent
		}

		public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
			Task {
				do {
					try await self.loadPhotos(results: results)
					Task { @MainActor in
						picker.dismiss(animated: true)
					}
				} catch {
					Log(error)
				}
			}
		}
		private func loadPhotos(results: [PHPickerResult]) async throws {
			let existingSelection = parent.attachments
			parent.attachments.removeAll(where: { $0.isLocalURL })
			for result in results {
				let id = result.assetIdentifier!
				let firstItem = existingSelection.first(where: { $0.identifier == id })
				if let firstItem {
					parent.attachments.append(firstItem)
					continue
				}
				let itemProvider = result.itemProvider
				let item = try await loadPhoto(item: itemProvider)
				switch item {
				case let uiImage as UIImage:
					do {
						guard let imageURL = try await uiImage.temporaryLocalFileUrl(id: UUID().uuidString, quality: 1) else {
							return
						}
						let attachment = XAttachment(url: imageURL.absoluteString, type: .photo, identifier: id)
						parent.attachments.append(attachment)
					} catch {
						Log(error.localizedDescription)
					}
				case let movieURL as URL:
					let attachment = XAttachment(url: movieURL.absoluteString, type: .video, identifier: id)
					parent.attachments.append(attachment)
				default:
					break
				}
			}
		}
		private func loadPhoto(item: sending NSItemProvider) async throws -> sending NSItemProviderReading {
			if item.canLoadObject(ofClass: UIImage.self) {
				return try await item.loadObject(ofClass: UIImage.self)
			} else if item.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
				let url = try await item.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier)
				return url as NSItemProviderReading
			}
			fatalError()
		}
	}
}

public extension PhotoPicker {
	func filter(_ filter: PHPickerFilter?) -> Self {
		then({ $0.filter = filter })
	}
	func preferredAssetRepresentationMode(_ mode: PHPickerConfiguration.AssetRepresentationMode) -> Self {
		then({ $0.preferredAssetRepresentationMode = mode })
	}
	func preselectedAssetIdentifiers(_ identifiers: [String]) -> Self {
		then({ $0.preselectedAssetIdentifiers = identifiers })
	}
	func selectionLimit(_ limit: Int) -> Self {
		guard multipleSelection else { return self }
		return then({ $0.selectionLimit = limit })
	}
	func keepSelectionOrder() -> Self {
		guard multipleSelection else { return self }
		return then({ $0.selection = .ordered })
	}
}

public extension NSItemProvider {
	func loadPhoto() async throws -> NSItemProviderReading {
		if self.canLoadObject(ofClass: UIImage.self) {
			return try await self.loadObject(ofClass: UIImage.self)
		} else if self.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
			let url = try await self.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier)
			return url as NSItemProviderReading
		}

		fatalError()
	}
}

public extension UIImage {
	convenience init(movieURL url: URL) throws {
		let asset: AVAsset = AVURLAsset(url: url)
		let generator = AVAssetImageGenerator(asset: asset)
		let cgImage = try generator.copyCGImage(at: asset.duration, actualTime: nil)
		self.init(cgImage: cgImage)
	}
}
public extension NSItemProvider {
	func loadFileRepresentation(forTypeIdentifier typeIdentifier: String) async throws -> URL {
		try await withCheckedThrowingContinuation { continuation in
			self.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
				if let error = error {
					return continuation.resume(throwing: error)
				}

				guard let url = url else {
					return continuation.resume(throwing: NSError())
				}

				let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
				try? FileManager.default.removeItem(at: localURL)

				do {
					try FileManager.default.copyItem(at: url, to: localURL)
				} catch {
					return continuation.resume(throwing: error)
				}

				continuation.resume(returning: localURL)
			}.resume()
		}
	}

	func loadObject(ofClass aClass: NSItemProviderReading.Type) async throws -> NSItemProviderReading {
		try await withCheckedThrowingContinuation { continuation in
			self.loadObject(ofClass: aClass) { data, error in
				if let error = error {
					return continuation.resume(throwing: error)
				}

				guard let data = data else {
					return continuation.resume(throwing: NSError())
				}

				continuation.resume(returning: data)
			}.resume()
		}
	}
}
