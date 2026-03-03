//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public enum MediaPickerLoadingState<T: Sendable>: Equatable, Sendable {
    case empty
    case loading(Progress)
    case success(T)
    case failure(Error)

    public static func == (lhs: MediaPickerLoadingState, rhs: MediaPickerLoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            true
        case (.loading(_), .loading(_)):
            true
        case (.success(_), .success(_)):
            true
        case (.failure(_), .failure(_)):
            true
        default:
            false
        }
    }
}
