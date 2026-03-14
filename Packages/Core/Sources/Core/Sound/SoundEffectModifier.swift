//
//  SoundEffectModifier.swift
//  Core
//
//  Created by Aung Ko Min on 10/3/26.
//
import SwiftUI
import CoreHaptics
import UniformTypeIdentifiers
import AVFoundation

public extension View {

	func soundEffect<Trigger: Equatable>(
		_ audio: SoundEffect,
		trigger: Trigger
	) -> some View {
		modifier(SoundEffectModifier(audio: audio, trigger: trigger))
	}

	func soundEffect<Trigger: Equatable>(
		_ sound: Sound,
		trigger: Trigger
	) -> some View {
		modifier(
			SoundEffectModifier(
				audio: .init(sound.rawValue, bundle: .module),
				trigger: trigger
			)
		)
	}
}

private struct SoundEffectModifier<Trigger: Equatable>: ViewModifier {

	var trigger: Trigger

	// TODO: Remove from protocol
	var initialVelocity: CGFloat = 0

	var audio: SoundEffect

	init(audio: SoundEffect, trigger: Trigger) {
		self.audio = audio
		self.trigger = trigger
	}

	let engine: AnySoundEffectPlayer = .shared

	func body(content: Content) -> some View {
		content
			.onChange(of: trigger) { _, _ in
				Task(priority: .userInitiated) {
					try await engine.play(audio)
				}
			}
			.onAppear {
				Task {
					try await engine.register(audio)
				}
			}
			.onChange(of: audio) { oldValue, newValue in
				guard oldValue != newValue else { return }

				Task {
					try await engine.unregister(oldValue)
					try await engine.register(newValue)
				}
			}
			.onDisappear {
				Task {
					try await engine.unregister(audio)
				}
			}
	}
}
