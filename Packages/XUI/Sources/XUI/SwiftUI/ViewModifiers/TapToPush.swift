//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

private struct PushViewModifier<Destination: View>: ViewModifier {
    @ViewBuilder var destination: () -> Destination
    func body(content: Content) -> some View {
        NavigationLink {
            destination()
        } label: {
            content
        }
        .buttonStyle(.borderless)
    }
}

public extension View {
    func tapToPush(@ViewBuilder content: @escaping () -> some View) -> some View {
        ModifiedContent(content: self, modifier: PushViewModifier(destination: content))
    }
}
