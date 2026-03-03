//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct NumberTextField: View {
    private var value: Binding<Int>
    private let title: String
    private let delima: String?

    public init(value: Binding<Int>, title: String, delima: String? = nil) {
        self.value = value
        self.title = title
        self.delima = delima
    }

    public var body: some View {
        HStack {
            Text(.init(title))
                .foregroundStyle(value.wrappedValue > 0 ? .secondary : .primary)

            TextField(
                "\(delima.str)",
                text: .init(get: { value.wrappedValue.description }, set: { setValue($0) })
            )
            .keyboardType(.numberPad)
            .bold()
            .multilineTextAlignment(.trailing)
        }
    }

    private func getValue() -> String {
        if value.wrappedValue == 0 { return String() }
        return "\(delima.str)\(value)"
    }

    private func setValue(_ newValue: String) {
        value.wrappedValue = Int(newValue.replace(delima.str, with: "")) ?? 0
    }
}
