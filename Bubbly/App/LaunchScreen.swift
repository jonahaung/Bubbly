//
//  LaunchScreen.swift
//  Bubbly
//
//  Created by Aung Ko Min on 17/8/25.
//

import SwiftUI
import Services
import XUI
import Core
import FirebaseMessaging

struct LaunchScreen: View {

	@Environment(AuthService.self) private var authService
	@State private var tokenObserver: NSObjectProtocol?

	@State private var currentPhraseIndex = 0
	private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
	@State private var thinking: Bool = false

	let phrases = [
		"Bubbly              ",
		"Connecting People   ",
		"Embracing Pravicy   "
	]

	var body: some View {
		VStack {
			Spacer()
			Logo()
				.frame(square: 100)
			Spacer()
			HStack {
				Image(systemName: "sparkles")
					.font(.title)
					.foregroundStyle(EllipticalGradient(colors: [.blue, .indigo], center: .center, startRadiusFraction: 0.0, endRadiusFraction: 0.5))
					.phaseAnimator([false, true]) { ai, thinking in
						ai
							.symbolEffect(.wiggle.byLayer, value: thinking)
							.symbolEffect(.bounce.byLayer, value: thinking)
							.symbolEffect(.breathe.byLayer, value: thinking)
					}
				Spacer()
				HStack(spacing: 0) {
					ForEach(Array(phrases[currentPhraseIndex].enumerated()), id: \.offset) { index, letter in
						Text(String(letter))
							.foregroundStyle(.blue)
							.hueRotation(.degrees(thinking ? 220 : 0))
							.opacity(thinking ? 0 : 1)
							.scaleEffect(thinking ? 1.5 : 1, anchor: .bottom)
							.animation(.easeInOut(duration: 0.5).delay(1).repeatForever(autoreverses: false).delay(Double(index) / 20), value: thinking)
					}
				}
				Spacer()
				Spacer()
			}
			.padding(.horizontal, 90)
			Spacer()
			Button("Start") {
				NotificationCenter.default.post(name: .receiveDeviceToken, object: "")
			}
			Spacer()
		}
		.onAppear {
			thinking = true
			observeDeviceToken()
		}
		.onDisappear(perform: removeDeviceTokenObserver)
		.onReceive(timer) { _ in
			withAnimation {
				currentPhraseIndex = (currentPhraseIndex + 1) % phrases.count
			}
		}

	}

	private func observeDeviceToken() {
		tokenObserver = NotificationCenter.default.addObserver(
			forName: .receiveDeviceToken,
			object: nil,
			queue: .main
		) { notification in
			MainActor.assumeIsolated {
				if notification.object is String {
					authService.observeAuthState()
				}
			}
		}
	}

	private func removeDeviceTokenObserver() {
		if let observer = tokenObserver {
			NotificationCenter.default.removeObserver(observer)
			tokenObserver = nil
			Log("🧹 Removed device token observer")
		}
	}
}
struct Logo: View {

	@State private var angle = -60.0
	@State private var scale = 0.25
	@State private var breatheIn = true
	@State private var breatheOut = false
	let flowerColor = Color(#colorLiteral(red: 0.3084011078, green: 0.5618229508, blue: 0, alpha: 1))

	var body: some View {
		ZStack {
			ForEach(0 ..< 6) { item in
				Image(systemName: "viewfinder")
				// Image(systemName: "seal")
				// Image(systemName: "rhombus.fill")
				// Image(systemName: "shield")
				// Image(systemName: "pentagon")
					.font(.system(size: 150))
					.foregroundColor(flowerColor)
					.offset(y: -80)
					.rotationEffect(.degrees(Double(item)) * angle)
					.scaleEffect(CGFloat(scale))
					.hueRotation(.degrees(angle))
					.blendMode(.difference)
					.animation(.easeInOut(duration: 4).delay(0.75).repeatForever(autoreverses: true), value: scale)
					.onAppear {
						angle = 60.0
						scale = 1
					}
			}
		}
	}
}
