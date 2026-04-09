//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

/// Standard execute button for tool views
public struct ToolExecuteButton: View {
    public let title: String
    public let systemImage: String?
    public let isRunning: Bool
    public let action: () -> Void

    public init(
        _ title: String,
        systemImage: String? = nil,
        isRunning: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isRunning = isRunning
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isRunning {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(isRunning ? "\(title)..." : title)
            }
            .foregroundStyle(Color.systemBackground)
            .flexible(.horizontal)
        }
        .buttonStyle(.roundedButtonStyle)
        .disabled(isRunning)
    }
}

/// Standard input field for tool views
public struct ToolInputField: View {
    public let label: String
    @Binding public var text: String
    public let placeholder: String

    public init(label: String, text: Binding<String>, placeholder: String = "") {
        self.label = label
        _text = text
        self.placeholder = placeholder
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(minHeight: 60, maxHeight: 120)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
        }
    }
}
