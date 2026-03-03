//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public enum ImageViewTapAction {
    case openPhotoViewer
    case custom(() -> Void)
    case none
}
