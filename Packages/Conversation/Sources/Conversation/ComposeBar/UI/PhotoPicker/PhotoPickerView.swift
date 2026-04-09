// © 2026 Aung Ko Min

#if os(iOS)
//
    // Copyright © 2026 Aung Ko Min. All rights reserved.
//

//
    //  PhotoPickerView.swift
    //  MsgRoomMain
//
    //  Created by Aung Ko Min on 13/2/26.
//
    import PhotosUI
    import SwiftUI

    struct PhotoPickerView: View {
        @Environment(PhotoPickerManager.self) private var manager
        var body: some View {
            PhotosPicker(
                selection: manager.photoPickerItems,
                maxSelectionCount: 5,
                selectionBehavior: .continuousAndOrdered,
                preferredItemEncoding: .automatic,
                photoLibrary: .shared(),
            ) {
                EmptyView()
            }
            .photosPickerStyle(.inline)
            .photosPickerDisabledCapabilities(.collectionNavigation)
            .ignoresSafeArea()
        }
    }

#endif
