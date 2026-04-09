//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

public struct DismissButton: View {
    private let isProtected: Bool
    private let title: String
    private let dismiss: DismissAction

    public init(
        dismiss: DismissAction,
        isProtected: Bool = false,
        title: String = "Done"
    ) {
        self.isProtected = isProtected
        self.title = title
        self.dismiss = dismiss
    }

    public var body: some View {
        if isProtected {
            Text(.init(title))
                .confirmationDialogue(message: "Are you sure to close?") {
                    Button("Continue to close", role: .destructive) {
                        dismiss()
                    }
                }
        } else {
            Button(.init(title), role: .cancel) {
                dismiss()
            }
        }
    }
}

public struct CancelButton: View {
    @Environment(\.presentationMode) var presentationMode
    public init() {}
    public var body: some View {
        Button(role: .cancel) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
