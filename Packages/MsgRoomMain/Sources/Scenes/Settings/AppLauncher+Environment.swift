//
//  AppLauncher+Environment.swift
//  Services
//
//  Created by Aung Ko Min on 16/5/25.
//

import SwiftUI

public extension EnvironmentValues {
	@Entry var appLauncher: AppLauncher = {
		preconditionFailure(
			"AppLauncher not injected. Inject an instance via .environment(appLauncher) from a main-actor context (e.g., in your App)."
		)
	}()

	subscript(_ type: AppLauncher.Type) -> AppLauncher {
		get { appLauncher }
		set { appLauncher = newValue }
	}
}
