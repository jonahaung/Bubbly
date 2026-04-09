// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

struct BackgroundView: View {
    @Environment(ChatManager.self) private var manager
    var body: some View {
        Image("bg_default")
            .resizable(resizingMode: .tile)
            .foregroundStyle(Color.secondaryText)
            .background(manager.state.theme.backgroundColor)
            .blendMode(.plusLighter)
            .backgroundExtensionEffect()
            .geometryGroup()
            .allowsHitTesting(false)
            .equatable(by: manager.state.theme)
    }
}
