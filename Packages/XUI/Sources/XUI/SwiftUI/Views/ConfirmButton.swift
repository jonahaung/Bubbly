//
//  ConfirmButton.swift
//
//
//  Created by Aung Ko Min on 20/2/23.
//

import SwiftUI

public struct ComfirmButton<Content: View>: View {
    private let message: String
    private let action: () -> Void
    private let label: () -> Content

    public init(_ message: String, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Content) {
        self.message = message
        self.action = action
        self.label = label
    }

    @State private var isShown = false

    public var body: some View {
        label()
            ._comfirmationDialouge("Attention", message: "Comfirm to \(message)") {
                Button(action: action) {
                    Text("Continue \(message)")
                }
            }
    }
}
