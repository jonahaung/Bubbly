// © 2026 Aung Ko Min

import Core
import Services
import SwiftUI
import XUI

struct TimeSeparator: View, @MainActor Equatable {
    @Environment(\.typography) private var typography
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
    let dateString: String?
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.dateString == rhs.dateString
    }
}
