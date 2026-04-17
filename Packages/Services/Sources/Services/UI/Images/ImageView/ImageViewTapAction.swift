// © 2026 Aung Ko Min

import Foundation

public enum ImageViewTapAction {
    case openPhotoViewer
    case custom(() -> Void)
    case none
}
