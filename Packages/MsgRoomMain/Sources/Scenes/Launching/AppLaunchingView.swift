//
//  LaunchingSwitch.swift
//  Bubbly
//
//  Created by Aung Ko Min on 18/11/25.
//

import SwiftUI

@MainActor
public struct AppLaunchingView: View {

	@Environment(AppLauncher.self) private var launcher

	public init() {}

	public var body: some View {
		switch launcher.route {
		case .loading:
			LaunchScreen()
		case .getStarted:
			AuthFlow()
		case .main(let currentUser):
			RootView()
				.msgRoomEntryPoint(currentUser)
		}
	}
}
