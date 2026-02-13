import AudioToolbox
import CoreHaptics
import SwiftUI

public struct Haptics: Sendable {
	public static var shared: Haptics {
		get { _shared.value }
		set { _shared.value = newValue }
	}

	private nonisolated(unsafe) static var _shared = Mutex(Haptics())

	@MainActor public static func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle,
	                                   _ intensity: CGFloat)
	{
		Haptics.shared.play(style, intensity: intensity)
	}

	@MainActor private func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle,
	                             intensity: CGFloat)
	{
		UIImpactFeedbackGenerator(style: style)
			.impactOccurred(intensity: intensity)
	}

	@MainActor public func generateNotificationFeedback(style: UINotificationFeedbackGenerator
		.FeedbackType)
	{
		UINotificationFeedbackGenerator().notificationOccurred(style)
	}

	private func generateLegacyFeedback() {
		AudioServicesPlaySystemSound(1519)
		AudioServicesPlaySystemSound(1520)
		AudioServicesPlaySystemSound(1521)
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
	}
}
