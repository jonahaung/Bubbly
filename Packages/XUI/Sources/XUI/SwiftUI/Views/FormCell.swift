//
//  FormCell.swift
//  RoomRentalDemo
//
//  Created by Aung Ko Min on 19/1/23.
//

import SwiftUI

public struct FormCell: View {
    @ViewBuilder private var left: () -> any View
    @ViewBuilder private var right: () -> any View

    public init(
        @ViewBuilder left: @escaping () -> any View,
        @ViewBuilder right: @escaping () -> any View
    ) {
        self.left = left
        self.right = right
    }

    public init(_ title: String, _ subtitle: String) {
        left = { Text(title) }
        right = {
            Text(subtitle)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }

    public var body: some View {
        HStack {
            AnyView(left())
            Spacer()
            AnyView(right())
        }
        .lineLimit(1)
    }
}
