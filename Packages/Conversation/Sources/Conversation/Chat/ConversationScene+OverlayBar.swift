// © 2026 Aung Ko Min

import Database
import Services
import SwiftUI
import XUI

struct ConversationSceneOverlayBar: View {
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            TopBar()
            FloatingDateView()
            Spacer()
            AccessoryBar()
            ComposeBar()
        }
    }
}
