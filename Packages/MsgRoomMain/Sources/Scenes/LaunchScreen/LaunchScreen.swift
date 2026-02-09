//
//  LaunchScreen.swift
//  Bubbly
//
//  Created by Aung Ko Min on 17/8/25.
//

import Core
import FirebaseMessaging
import Services
import SwiftUI
import XUI

struct LaunchScreen: View {
	@Environment(AppLauncher.self) private var launcher
	var body: some View {
		ZStack {
			LoadingIndicator(40)
		}
		.task {
			await launcher.startEvaluate()
		}
		.statusBarHidden()
	}
}
