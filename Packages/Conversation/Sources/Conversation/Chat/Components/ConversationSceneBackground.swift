//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct ConversationSceneBackground: View, Equatable {
    let color: Color
    var body: some View {
        color
            .overlay {
                Image("adaptive")
                    .resizable(resizingMode: .tile)
                    .foregroundStyle(
                        AngularGradient(colors: Color.adaptableGrayColors, center: .topLeading)
                    )
                    .clipped()
            }
            .backgroundExtensionEffect()
            .equatable(by: color)
    }
}
