// © 2026 Aung Ko Min

import Core
import Database
import SwiftUI

extension MsgCell {
    struct CellSpacer: View {
        var body: some View {
            Spacer()
                .frame(height: ChatLayoutConstants.Cell.sectionSpacing)
        }
    }
}
