import Core
import FirebaseMessaging
import Services
import SwiftUI
import XUI

struct LaunchScreen: View {
	let appLauncher: AppLauncher
	var body: some View {
		ZStack {
			LoadingIndicator(40)
		}
		.task {
			await appLauncher.startEvaluate()
		}
		.statusBarHidden()
	}
}
