//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public enum EULA {
    static let key = "com.jonahaung.hasShownEULA"
    public static var hasShown: Bool {
        get {
            UserDefaults.standard.bool(forKey: key)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: key)
        }
    }
}

public struct EULAView: View {
    private let text: String
    private let onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    public init(text: String, _ onClose: (() -> Void)? = nil) {
        self.onClose = onClose
        self.text = text
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                Text("End-User license agreement ('Agreement')")
                    .font(.headline)
                Text(.init(text))
                    .font(.footnote)
                    .textSelection(.enabled)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            let hasAgreedEULA = EULA.hasShown
            Button {
                EULA.hasShown = true
                dismiss()
                onClose?()
            } label: {
                Text(hasAgreedEULA ? "Close" : "I agree and continue")
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .statusBarHidden(true)
    }
}
