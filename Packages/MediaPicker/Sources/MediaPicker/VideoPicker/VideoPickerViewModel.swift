//
//  VideoPickerViewModel.swift
//  MediaPicker
//
//  Created by Aung Ko Min on 2024/04/22.
//

import Foundation
@preconcurrency import AVFoundation
import SwiftUI
import PhotosUI

@MainActor
@Observable
final class VideoPickerViewModel: @unchecked Sendable {

	struct ProfileVideo: Transferable, @unchecked Sendable {
        let asset: AVAsset
        static var transferRepresentation: some TransferRepresentation {
            FileRepresentation(importedContentType: .movie) {
                let asset = AVAsset(url: $0.file)
                _ = try? await asset.load(.isPlayable)
                return Self.init(asset: asset)
            }
        }
    }

	private(set) var loadState: MediaPickerLoadingState<AVAsset> = .empty

	var selection: PhotosPickerItem? {
        didSet {
            if let selection {
                let progress = loadTransferable(from: selection)
                loadState = .loading(progress)
            } else {
                loadState = .empty
            }
        }
    }

    private func loadTransferable(from videoSelection: PhotosPickerItem) -> Progress {
        return videoSelection.loadTransferable(type: ProfileVideo.self) { result in
            DispatchQueue.main.async {
                guard videoSelection == self.selection else {
                    debugPrint("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let profile?):
                    self.loadState = .success(profile.asset)
                case .failure(let error):
                    self.loadState = .failure(error)
                default:
                    self.loadState = .empty
                }
            }
        }
    }
}
