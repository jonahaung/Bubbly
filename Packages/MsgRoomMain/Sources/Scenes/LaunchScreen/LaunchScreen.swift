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
			AnimatedText(text: "Bubbly", preset: .spring)
        }
        .task {
			try? await Task.sleep(seconds: 1)
            await appLauncher.startEvaluate()
        }
        .statusBarHidden()
    }
}

import SwiftUI

public struct AnimatedText: View {

	public enum AnimationPreset {
		case spring
		case wave
		case bounce
		case typewriter
	}

	public let letters: [Character]

	@State private var isVisible = false
	@State private var offset: CGSize
	@State private var isDisappearing = false

	private let preset: AnimationPreset
	private let initialOffset: CGSize
	private let delayStep: Double
	private let jitter: CGFloat
	private let style: (Character) -> Text

	public init(
		text: String,
		preset: AnimationPreset = .spring,
		initialOffset: CGSize = CGSize(width: 0, height: 300),
		delayStep: Double = 0.05,
		jitter: CGFloat = 0,
		@ViewBuilder style: @escaping (Character) -> Text = { Text(String($0)).font(.largeTitle.bold()) }
	) {
		self.letters = Array(text)
		self.preset = preset
		self.initialOffset = initialOffset
		self.delayStep = delayStep
		self.jitter = jitter
		self.style = style
		self._offset = State(initialValue: initialOffset)
	}

	// MARK: - Body

	public var body: some View {
		HStack(spacing: 0) {
			ForEach(letters.indices, id: \.self) { index in
				style(letters[index])
					.rotationEffect(rotation(for: index), anchor: .bottom)
					.offset(offsetFor(index))
					.opacity(opacity(for: index))
					.animation(
						animation(for: index),
						value: offset
					)
			}
		}
		.padding()
		.onAppear {
			isDisappearing = false
			withAnimation {
				offset = .zero
				isVisible = true
			}
		}
		.onDisappear {
			isDisappearing = true
			withAnimation {
				offset = initialOffset
				isVisible = false
			}
		}
	}
}

private extension AnimatedText {

	func animation(for index: Int) -> Animation {
		baseAnimation()
			.delay(staggerDelay(for: index))
	}

	func baseAnimation() -> Animation {
		switch preset {
		case .spring:
			return .interpolatingSpring(stiffness: 170, damping: 15)
		case .wave:
			return .easeInOut(duration: 0.6)
		case .bounce:
			return .spring(response: 0.4, dampingFraction: 0.5)
		case .typewriter:
			return .easeOut(duration: 0.2)
		}
	}

	func staggerDelay(for index: Int) -> Double {
		if isDisappearing {
			return Double(letters.count - index) * delayStep
		} else {
			return Double(index) * delayStep
		}
	}
}

private extension AnimatedText {

	func offsetFor(_ index: Int) -> CGSize {
		var base = offset

		// Add jitter if enabled
		if jitter > 0 {
			let randomX = CGFloat.random(in: -jitter...jitter)
			let randomY = CGFloat.random(in: -jitter...jitter)
			base.width += randomX
			base.height += randomY
		}

		// Wave effect
		if preset == .wave {
			let wave = sin(Double(index)) * 10
			base.height += isVisible ? 0 : CGFloat(wave)
		}

		return base
	}

	func rotation(for index: Int) -> Angle {
		switch preset {
		case .bounce:
			return .degrees(isVisible ? 0 : 180)
		default:
			return .degrees(isVisible ? 0 : 360)
		}
	}

	func opacity(for index: Int) -> Double {
		switch preset {
		case .typewriter:
			return isVisible ? 1 : 0
		default:
			return 1
		}
	}
}
