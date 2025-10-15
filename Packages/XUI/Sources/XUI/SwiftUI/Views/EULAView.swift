//
//  EULA.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 24/4/23.
//

import SwiftUI

public enum EULA {
    static let key = "com.jonahaung.hasShownEULA"
    public static var hasShown: Bool {
        get {
            UserDefaults.standard.bool(forKey: Self.key)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Self.key)
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
                    ._borderedProminentButtonStyle()
            }
            .padding(.horizontal)
        }
        .statusBarHidden(true)
    }
}
