//  TimeSeparator.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Services

struct TimeSeparator: View, @MainActor Equatable {

    @Environment(\.typography) private var typography
    let dateString: String?
    
    var body: some View {
        Text(dateString ?? "")
            .foregroundStyle(Color.secondaryText)
        .frame(
            height: ChatLayoutConstants.Cell.timeSeparatorHeight, alignment: .bottom
        )
        .font(Typography.system.footnote)
        .padding(.horizontal, Padding.lg)
        .padding(.bottom, Padding.xs)
        .allowsHitTesting(false)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.dateString == rhs.dateString
    }
}
