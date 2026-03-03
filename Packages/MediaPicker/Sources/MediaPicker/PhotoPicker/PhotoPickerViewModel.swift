//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
@Observable
public final class PhotoPickerViewModel {
    // MARK: - State

    private(set) var imageState: MediaPickerLoadingState<UIImage> = .empty
    public var pickedPhoto: PickedPhoto?

    // MARK: - Selection

    public var imageSelection: PhotosPickerItem? {
        willSet {
            guard let newValue else {
                updateState(.empty, pickedPhoto: nil)
                pickedPhoto = nil
                return
            }
            loadTransferable(from: newValue)
        }
    }

    // MARK: - Init

    public init(_ pickedPhoto: PickedPhoto?) {
        _pickedPhoto = pickedPhoto
    }

    // MARK: - Private

    private func loadTransferable(from imageSelection: PhotosPickerItem) {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            do {
                if let item = try await imageSelection.loadTransferable(type: PickedPhoto.self) {
                    await updateState(.success(item.uiImage), pickedPhoto: item)
                } else {
                    await updateState(.empty, pickedPhoto: nil)
                }
            } catch {
                await updateState(.failure(error), pickedPhoto: nil)
            }
        }
    }

    private func updateState(_ state: MediaPickerLoadingState<UIImage>, pickedPhoto: PickedPhoto?) {
        imageState = state
        self.pickedPhoto = pickedPhoto
    }
}
