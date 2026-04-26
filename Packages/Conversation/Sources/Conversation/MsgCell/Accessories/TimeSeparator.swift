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
        VStack {
            if let dateString {
                Text(dateString)
            }
        }
        .font(typography.footnote.weight(.semibold))
        .foregroundStyle(Color.secondaryText)
        .frame(
            height: ChatLayoutConstants.Cell.timeSeparatorHeight
        )
        .flexible(.horizontal)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.dateString == rhs.dateString
    }
}
