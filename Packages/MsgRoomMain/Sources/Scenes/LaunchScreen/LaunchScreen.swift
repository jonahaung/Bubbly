// © 2026 Aung Ko Min

import Services
import SwiftUI
import XUI

struct LaunchScreen: View {
    let appLauncher: AppLauncher

    var body: some View {
        ProgressView()
            .controlSize(.mini)
            .statusBarHidden()
            .onTask {
                await appLauncher.startEvaluate()
            }
    }
}
