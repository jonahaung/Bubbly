//  CustomButton.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI
import Anima

@MainActor
public struct CustomButton<Content: View>: View {

    let label: () -> Content
    let action: () -> Void
    let onFinished: (() -> Void)?
    @State private var buttonIsPressing: Bool = false

    public init(action: @escaping () -> Void, label: @escaping () -> Content, onFinished: (() -> Void)? = nil) {
        self.label = label
        self.action = action
        self.onFinished = onFinished
    }

    public var body: some View {
        label()
            .opacity(buttonIsPressing ? 0.3 : 1.0)
            .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.5), trigger: buttonIsPressing, condition: { oldValue, newValue in
                !oldValue && newValue
            })
            ._onButtonGesture { pressing in
                buttonIsPressing = pressing
                if !pressing {
                    action()
                }
            } perform: {
                if let onFinished {
                    Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        onFinished()
                    }
                }
            }
            .allowsHitTesting(!buttonIsPressing)
    }
}
