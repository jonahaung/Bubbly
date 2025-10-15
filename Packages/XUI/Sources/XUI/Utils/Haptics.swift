//
//  Haptics.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 8/2/23.
//

import SwiftUI
import AudioToolbox
import CoreHaptics

public struct Haptics: Sendable {

    public static var shared: Haptics {
        get { _shared.wrappedValue }
        set { _shared.wrappedValue = newValue }
    }
	nonisolated(unsafe) private static var _shared = Atomic(wrappedValue: Haptics())

    @MainActor public static func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle, _ intensity: CGFloat) {
		Haptics.shared.play(style, intensity: intensity)
    }

	@MainActor private func play(
		_ style: UIImpactFeedbackGenerator.FeedbackStyle,
		intensity: CGFloat) {
		 UIImpactFeedbackGenerator(style: style)
			 .impactOccurred(intensity: intensity)
    }
    @MainActor public func generateNotificationFeedback(style: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(style)
    }

    private func generateLegacyFeedback() {
        AudioServicesPlaySystemSound(1519)
        AudioServicesPlaySystemSound(1520)
        AudioServicesPlaySystemSound(1521)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
