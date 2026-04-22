// © 2026 Aung Ko Min

import Core
import Database
import SwiftUI

struct CellSpacer: View, @MainActor Equatable {
    var body: some View {
        Spacer()
            .frame(height: ChatLayoutConstants.Cell.sectionSpacing)
    }
    static func == (lhs: Self, rhs: Self) -> Bool {
       true
    }
}
