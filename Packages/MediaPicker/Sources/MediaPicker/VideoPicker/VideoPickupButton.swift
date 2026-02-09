//
//  VideoPickupButton.swift
//  MediaPicker
//
//  Created by Aung Ko Min on 2024/04/22.
//

@preconcurrency import AVKit
@preconcurrency import PhotosUI
import SwiftUI

public struct VideoPickupButton<Label: View>: View {
	@State private var model = VideoPickerViewModel()
	@Binding private var asset: AVAsset?

	/// Make the label builder main-actor–isolated, since it builds UI.
	private let label: @MainActor (MediaPickerLoadingState<AVAsset>) -> Label

	public init(pickedVideo asset: Binding<AVAsset?>,
	            @ViewBuilder label: @escaping @MainActor (MediaPickerLoadingState<AVAsset>)
	            	-> Label)
	{
		self.label = label
		_asset = asset
	}

	@MainActor
	public var body: some View {
		// Build a concrete Label value on the main actor so the PhotosPicker
		// closure doesn't capture Label.Type or MainActor state.
		let builtLabel: Label = label(model.loadState)

		return PhotosPicker(
			selection: $model.selection,
			matching: .videos,
			photoLibrary: .shared()
		) {
			builtLabel
		}
		.onChange(of: model.loadState) { _, newValue in
			switch newValue {
			case let .success(asset):
				self.asset = asset
			default:
				asset = nil
			}
		}
	}
}

struct GalleryView: View {
	struct Movie: Transferable {
		let url: URL
		static var transferRepresentation: some TransferRepresentation {
			FileRepresentation(contentType: .movie) { movie in
				SentTransferredFile(movie.url)
			} importing: { received in
				let copy = URL.documentsDirectory.appending(path: "movie.mp4")
				if FileManager.default.fileExists(atPath: copy.path()) {
					try FileManager.default.removeItem(at: copy)
				}
				try FileManager.default.copyItem(at: received.file, to: copy)
				return Self(url: copy)
			}
		}
	}

	@State private var selectedItem: PhotosPickerItem?
	@State private var player = AVPlayer()

	var body: some View {
		VStack {
			VideoPlayer(player: player)
				.frame(width: 345, height: 345)
				.padding(20)

			PhotosPicker(selection: $selectedItem, matching: .videos) {
				Image(systemName: "video.circle").resizable()
					.frame(width: 55, height: 55)
			}
		}
		.onChange(of: selectedItem) {
			Task {
				do {
					if let movie = try await selectedItem?.loadTransferable(type: Movie.self) {
						player = AVPlayer(url: movie.url)
					}
				} catch {
					debugPrint(error)
				}
			}
		}
	}
}
