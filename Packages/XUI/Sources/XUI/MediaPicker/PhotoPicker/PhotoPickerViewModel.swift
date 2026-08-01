//
// Copyright © 2026 Aung Ko Min. All rights reserved.
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
    @ObservationIgnored private var loadingTask: Task<Void, Never>?

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

    

    public init(_ pickedPhoto: PickedPhoto?) {
        _pickedPhoto = pickedPhoto
    }

    // MARK: - Private

    private func loadTransferable(from imageSelection: PhotosPickerItem) {
        loadingTask?.cancel()
        loadingTask = Task { [weak self] in
            guard let self else { return }
            do {
                if let item = try await imageSelection.loadTransferable(type: PickedPhoto.self) {
                    guard !Task.isCancelled else { return }
                    updateState(.success(item.uiImage), pickedPhoto: item)
                } else {
                    updateState(.empty, pickedPhoto: nil)
                }
            } catch is CancellationError {
            } catch {
                updateState(.failure(error), pickedPhoto: nil)
            }
        }
    }

    private func updateState(_ state: MediaPickerLoadingState<UIImage>, pickedPhoto: PickedPhoto?) {
        imageState = state
        self.pickedPhoto = pickedPhoto
    }
}
