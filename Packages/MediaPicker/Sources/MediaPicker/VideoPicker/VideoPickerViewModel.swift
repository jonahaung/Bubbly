//
//  VideoPickerViewModel.swift
//  MediaPicker
//
//  Created by Aung Ko Min on 2024/04/22.
//

@preconcurrency import AVFoundation
import Foundation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class VideoPickerViewModel: @unchecked Sendable {
    struct ProfileVideo: Transferable, @unchecked Sendable {
        let asset: AVAsset
        static var transferRepresentation: some TransferRepresentation {
            FileRepresentation(importedContentType: .movie) {
                let asset = AVAsset(url: $0.file)
                _ = try? await asset.load(.isPlayable)
                return Self(asset: asset)
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
        videoSelection.loadTransferable(type: ProfileVideo.self) { result in
            DispatchQueue.main.async {
                guard videoSelection == self.selection else {
                    debugPrint("Failed to get the selected item.")
                    return
                }
                switch result {
                case let .success(profile?):
                    self.loadState = .success(profile.asset)
                case let .failure(error):
                    self.loadState = .failure(error)
                default:
                    self.loadState = .empty
                }
            }
        }
    }
}
