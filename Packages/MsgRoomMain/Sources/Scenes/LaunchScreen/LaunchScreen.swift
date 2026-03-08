//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import FirebaseMessaging
import Services
import SwiftUI
import XUI

struct LaunchScreen: View {
    let appLauncher: AppLauncher
    var body: some View {
        ZStack {
			TextDemo()
        }
        .task {
			try? await Task.sleep(seconds: 1)
            await appLauncher.startEvaluate()
        }
        .statusBarHidden()
    }
}

struct TextDemo: View {

	let letters = Array("Bubbly")

	@State private var enabled = false
	@State private var dragAmount = CGSize(width: 0, height: UIApplication.shared.screenSize().height)

	var body: some View {
		HStack(spacing: 0) {
			ForEach(0..<letters.count, id: \.self) { num in
				Text(String(letters[num]))
					.font(.largeTitle.bold())
					.rotationEffect(.degrees(enabled ? 0 : 360), anchor: .bottom)
					.offset(dragAmount)
					.animation(.interpolatingSpring(stiffness: 170, damping: 15).delay(Double(num) / 20), value: dragAmount)
			}
		}
		.padding()
		.onAppear {
			dragAmount = .zero
			enabled.toggle()
		}
	}
}
struct ChainedSpring: View {
	@State private var moving = false

	// Added constants for common values
	private let baseSize: CGFloat = 20
	private let sizeIncrement: CGFloat = 30
	private let delayIncrement: CGFloat = 0.05
	private let circleCount = 8

	// Added AnimatedCircle view component
	private struct AnimatedCircle: View {
		let size: CGFloat
		let delay: Double
		let moving: Bool

		var body: some View {
			Circle()
				.stroke(lineWidth: 5)
				.frame(width: size, height: size)
				.rotation3DEffect(.degrees(75), axis: (x: 1, y: 0, z: 0))
				.offset(y: moving ? 150 : -180)
				.animation(
					.bouncy(duration: 0.5, extraBounce: 0.25).repeatForever(autoreverses: true)
					.delay(delay),
					value: moving
				)
		}
	}

	var body: some View {
		ZStack {
			ForEach(0..<circleCount, id: \.self) { index in
				AnimatedCircle(
					size: baseSize + (CGFloat(index) * sizeIncrement),
					delay: Double(index) * delayIncrement,
					moving: moving
				)
			}
		}
		.onAppear {
			moving.toggle()
		}
	}
}

enum AnimationPhase {
	case initial, drawCircle, scaleGreen, showCheckmark
}

struct ActivityProgressAnimation: View {
	// Add state for animation control
	@Binding var isAnimating: Bool

	var body: some View {
		VStack {
			ZStack {
				Circle() // Blue circle
					.trim(from: 0.0, to: isAnimating ? 0.99 : 0.0)
					.stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round))
					.frame(width: 100, height: 100)

					.rotationEffect(.degrees(-90))
					.phaseAnimator([AnimationPhase.initial, .drawCircle], trigger: isAnimating) { content, phase in
						content
					} animation: { phase in
							.bouncy(duration: 1)
					}

//				Circle() // Green circle
//					.frame(width: 96, height: 96)
//
//					.scaleEffect(isAnimating ? 1 : 0)
//					.phaseAnimator([AnimationPhase.drawCircle, .scaleGreen], trigger: isAnimating) { content, phase in
//						content
//					} animation: { phase in
//							.bouncy(duration: 0.5, extraBounce: 0.1).delay(0.3)
//					}

					Image(systemName: "text.bubble.fill") // Checkmark
						.font(.largeTitle)
						.bold()

						.scaleEffect(isAnimating ? 1 : 0)
						.rotationEffect(.degrees(isAnimating ? 0 : -60), anchor: .bottom)
						.phaseAnimator([AnimationPhase.scaleGreen, .showCheckmark], trigger: isAnimating) { content, phase in
							content
						} animation: { phase in
								.bouncy(duration: 0.4, extraBounce: 0.4).delay(0.6)
						}
			}
			Button {
				isAnimating.toggle()
			} label: {
				ZStack {
					Text("Go")
				}
			}
			.padding()
			.buttonStyle(.borderedProminent)
		}
	}
}
