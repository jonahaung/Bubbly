import Foundation

public enum ImageViewTapAction {
	case openPhotoViewer
	case custom(() -> Void)
	case none
}
