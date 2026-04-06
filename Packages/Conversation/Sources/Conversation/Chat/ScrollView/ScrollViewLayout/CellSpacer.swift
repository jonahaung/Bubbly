
//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

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
