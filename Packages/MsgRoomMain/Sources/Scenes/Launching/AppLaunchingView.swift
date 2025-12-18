//
//  LaunchingSwitch.swift
//  Bubbly
//
//  Created by Aung Ko Min on 18/11/25.
//

import SwiftUI

public struct AppLaunchingView: View {

	@Environment(AppLauncher.self) private var launcher

	public init() {}

	public var body: some View {
		switch launcher.route {
		case .loading:
			ProgressView()
				.controlSize(.mini)
		case .getStarted:
			AuthFlow()
		case .main(let currentUser):
			MainTabView()
				.msgRoomEntryPoint(currentUser)
		}
	}
}
