//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// LoadingOverlay.swift (in XUI)
import SwiftUI

public struct LoadingOverlay: View {
    public init() {}

    public var body: some View {
        ZStack(alignment: .center) {
            Color.clear
                .contentShape(ContainerRelativeShape())
                .backgroundExtensionEffect()
                .onTapGesture { Loading.show(false) }
            LoadingIndicator(22)
        }
        .presentationBackground(.clear)
    }
}
