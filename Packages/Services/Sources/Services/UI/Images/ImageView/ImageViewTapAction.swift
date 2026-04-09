//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public enum ImageViewTapAction {
    case openPhotoViewer
    case custom(() -> Void)
    case none
}
