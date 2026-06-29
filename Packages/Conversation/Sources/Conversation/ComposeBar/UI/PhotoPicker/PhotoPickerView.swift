import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @Environment(PhotoPickerManager.self) private var manager
    var body: some View {
        PhotosPicker(
            selection: manager.photoPickerItems,
            maxSelectionCount: 5,
            selectionBehavior: .continuousAndOrdered,
            preferredItemEncoding: .automatic,
            photoLibrary: .shared()
        ) {
            EmptyView()
        }
        .photosPickerStyle(.inline)
        .photosPickerDisabledCapabilities(.collectionNavigation)
        .ignoresSafeArea()
    }
}
