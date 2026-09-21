//  SoundEffectModifier.swift
//
//  Copyright © 2026 Aung Ko Min.
//

//
//  SoundEffectModifier.swift
//  Core
//
//  Created by Aung Ko Min on 10/3/26.
//
import SwiftUI
import CoreHaptics
import AVFoundation
import UniformTypeIdentifiers

public extension View {
    func soundEffect(
        _ audio: SoundEffect,
        trigger: some Equatable
    ) -> some View {
        modifier(SoundEffectModifier(audio: audio, trigger: trigger))
    }

    func soundEffect(
        _ sound: Sound,
        trigger: some Equatable
    ) -> some View {
        modifier(
            SoundEffectModifier(
                audio: .init(sound.rawValue, bundle: .module),
                trigger: trigger
            )
        )
    }
}

// MARK: - SoundEffectModifier

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
                    do {
                        try await engine.play(audio)
                    } catch {
                        debugPrint(error)
                    }
                }
            }
            .onAppear {
                Task {
                    do {
                        try await engine.register(audio)
                    } catch {
                        debugPrint(error)
                    }
                }
            }
            .onChange(of: audio) { oldValue, newValue in
                guard oldValue != newValue else {
                    return
                }

                Task {
                    do {
                        try await engine.unregister(oldValue)
                        try await engine.register(newValue)
                    } catch {
                        debugPrint(error)
                    }
                }
            }
            .onDisappear {
                Task {
                    do {
                        try await engine.unregister(audio)
                    } catch {
                        debugPrint(error)
                    }
                }
            }
    }
}
