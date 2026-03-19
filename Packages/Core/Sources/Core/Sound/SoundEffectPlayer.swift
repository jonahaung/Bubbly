//
//  SoundEffectPlayer.swift
//  Core
//
//  Created by Aung Ko Min on 10/3/26.
//
import SwiftUI
import CoreHaptics
import UniformTypeIdentifiers
import AVFoundation

protocol SoundEffectPlayer: Sendable {
    func register(_ audio: SoundEffect) async throws
    func unregister(_ audio: SoundEffect) async throws
    func play(_ audio: SoundEffect) async throws
}
actor AnySoundEffectPlayer: SoundEffectPlayer {
	@MainActor static var shared = AnySoundEffectPlayer()

    let player: any SoundEffectPlayer

    init() {
        #if targetEnvironment(simulator)
        self.player = AVSoundEffectPlayer()
        #else
        if CHHapticEngine.capabilitiesForHardware().supportsAudio {
            self.player = HapticEngineSoundEffectPlayer()
        } else {
            self.player = EmptySoundEffectPlayer()
        }
        #endif
    }

    func register(_ audio: SoundEffect) async throws {
        try await player.register(audio)
    }

    func unregister(_ audio: SoundEffect) async throws {
        try await player.unregister(audio)
    }

    func play(_ audio: SoundEffect) async throws {
        try await player.play(audio)
    }
}

actor EmptySoundEffectPlayer: SoundEffectPlayer {
    func register(_ audio: SoundEffect) async throws {

    }

    func unregister(_ audio: SoundEffect) async throws {

    }

    func play(_ audio: SoundEffect) async throws {

    }
}

actor HapticEngineSoundEffectPlayer: SoundEffectPlayer {
    private var engine: CHHapticEngine?

    private struct SoundEffectReference {
        let resourceID: CHHapticAudioResourceID

        var count: Int = 1
    }

    private var registeredSounds: [URL: SoundEffectReference] = [:]

    private var didSetUp = false

    init() {

    }

    private func setUp() async throws {
        if didSetUp { return }
        defer { didSetUp = true }

        let audioSession: AVAudioSession? = await MainActor.run { () -> AVAudioSession? in
            SoundEffect.audioSession
        }
        if let audioSession {
            engine = try? CHHapticEngine(audioSession: audioSession)
        } else {
            engine = try? CHHapticEngine()
        }

        guard let engine else { return }

        if #available(iOS 16.0, *) {
            engine.playsAudioOnly = true
        }

        engine.isAutoShutdownEnabled = false

        engine.resetHandler = {
            try? engine.start()
        }
    }

    private func tearDown() async throws {
        guard let engine else { return }

        do {
            try await engine.stop()
        } catch {
            throw error
        }
    }

    func register(_ audio: SoundEffect) async throws {
        try await setUp()

        guard let engine else { return }

        for url in audio.urls {
            if var newRegisteredSound = registeredSounds[url] {
                newRegisteredSound.count += 1
                registeredSounds[url] = newRegisteredSound
            } else {
                let resourceID = try engine.registerAudioResource(url)

                let reference = SoundEffectReference(resourceID: resourceID)
                registeredSounds[url] = reference
            }
        }
    }

    func unregister(_ audio: SoundEffect) async throws {
        guard let engine else { return }

        for url in audio.urls {
            registeredSounds[url]?.count -= 1

            if registeredSounds[url]?.count == 0 {
                if let resourceID = registeredSounds[url]?.resourceID {
                    try engine.unregisterAudioResource(resourceID)
                }

                registeredSounds[url] = nil
            }
        }

        if registeredSounds.isEmpty {
            try await tearDown()
        }
    }

    func play(_ audio: SoundEffect) async throws {
        guard let engine else { return }

        try await engine.start()

        // TODO: Avoid playing the same sound twice if there are more variations.
        guard let url = audio.urls.randomElement() else { return }

        guard let resourceID = registeredSounds[url]?.resourceID else { return }

        try await withCheckedThrowingContinuation { continuation in
            let event = CHHapticEvent(
                audioResourceID: resourceID,
                parameters: [.init(parameterID: .audioVolume, value: Float(audio.volume))],
                relativeTime: CHHapticTimeImmediate
            )

            do {
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try engine.makeAdvancedPlayer(with: pattern)

                player.completionHandler = { x in
                    continuation.resume()
                }

                try player.start(atTime: CHHapticTimeImmediate)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

actor AVSoundEffectPlayer: SoundEffectPlayer {
    private struct SoundEffectReference {
        let id: UUID

        var count: Int
    }

    private var registeredSounds: [SoundEffect: SoundEffectReference] = [:]

    private var shouldDeactivateAudioSession = true

    private var didSetUp = false

    init() {

    }

    private func setUp() throws {
        if didSetUp { return }
        defer { didSetUp = true }
        guard SoundEffect.audioSession == nil else { return }

        let audioSession = AVAudioSession.sharedInstance()
        #if targetEnvironment(simulator)
        try audioSession.setCategory(.playback, mode: .default)
        #else
        try audioSession.setCategory(.ambient, mode: .default)
        #endif
        try audioSession.setActive(true)

        shouldDeactivateAudioSession = true
    }

    private func tearDown() throws {
        guard shouldDeactivateAudioSession else { return }

        let audioSession = AVAudioSession.sharedInstance()

        try audioSession.setActive(false)
    }

    func register(_ audio: SoundEffect) async throws {
        try setUp()

        if var updatedSound = registeredSounds[audio] {
            updatedSound.count += 1
            registeredSounds[audio] = updatedSound
        } else {
            let id = UUID()
            let sound = SoundEffectReference(id: id, count: 1)
            registeredSounds[audio] = sound
        }
    }

    func unregister(_ audio: SoundEffect) async throws {
        guard var registeredSound = registeredSounds[audio] else { return }

        registeredSound.count -= 1

        if registeredSound.count == 0 {
            registeredSounds[audio] = nil
        } else {
            registeredSounds[audio] = registeredSound
        }

        if registeredSounds.count == 0 {
            try? tearDown()
        }
    }

    func play(_ audio: SoundEffect) async throws {
        // TODO: Avoid playing the same sound twice if there are more variations.
        guard let url = audio.urls.randomElement() else {
            return
        }

        let player = AVAudioPlayerWithCompletionHandler(url: url, volume: audio.volume)

        try await withCheckedThrowingContinuation { continuation in
            player.play { result in
                continuation.resume(with: result)
            }
        }
    }
}

private class AVAudioPlayerWithCompletionHandler: NSObject, AVAudioPlayerDelegate {
    let url: URL

    let volume: Double

    var completion: (Result<Void, Error>) -> Void

    var player: AVAudioPlayer?

    init(url: URL, volume: Double) {
        self.url = url
        self.volume = volume
        self.completion = { _ in }
        self.player = nil
    }

    func play(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.delegate = self
            player.volume = Float(volume)
            player.play()
            self.player = player
        } catch {
            completion(.failure(error))
            tearDown()
        }
    }

    func stop() {
        player?.stop()
        tearDown()
    }

    func tearDown() {
        player = nil
        completion = { _ in }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            completion(.success(()))
        } else {
            completion(.failure(AVError(.unknown)))
        }
        tearDown()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error {
            completion(.failure(error))
        } else {
            completion(.failure(AVError(.unknown)))
        }
        tearDown()
    }
}
