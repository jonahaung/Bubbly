//
//  AudioService.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 7/4/24.
//

import AVFoundation
import CoreHaptics
import Foundation
import XUI

public final class AudioService: Sendable {
    private nonisolated(unsafe) var soundIDs: [String: SystemSoundID] = [:]

    public static var shared: AudioService {
        get { sharedValue.value }
        set { sharedValue.value = newValue }
    }

    static let sharedValue = Mutex(
        AudioService()
    )

    private var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    private init() {}

    // MARK: - Public Methods

    public func playSound(_ path: String) {
        guard !path.isEmpty else { return }
        playSound(path, isAlert: false)
    }

    public func playAlert(_ path: String) {
        guard !path.isEmpty else { return }
        playSound(path, isAlert: true)
    }

    public func playVibrateSound() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    public func stopAllSounds() {
        unloadAllSounds()
    }

    public func stopSound(_ path: String) {
        guard !path.isEmpty else { return }
        unloadSound(path)
    }

    // MARK: - Sound Management

    public func playSound(_ path: String, isAlert: Bool) {
        let soundID = loadSoundID(for: path)

        guard soundID != 0 else { return }

        if isAlert {
            AudioServicesPlayAlertSound(soundID)
        } else {
            AudioServicesPlaySystemSound(soundID)
        }
    }

    public func unloadAllSounds() {
        soundIDs.keys.forEach(unloadSound)
    }

    public func unloadSound(_ path: String) {
        guard let soundID = soundIDs[path] else { return }

        AudioServicesDisposeSystemSoundID(soundID)
        soundIDs.removeValue(forKey: path)
    }

    // MARK: - Private Helpers

    private func loadSoundID(for path: String) -> SystemSoundID {
        if let existingID = soundIDs[path] {
            return existingID
        }

        let url = URL(fileURLWithPath: path) as CFURL
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url, &soundID)

        if soundID != 0 {
            soundIDs[path] = soundID
        }

        return soundID
    }
}

// MARK: - Message Sounds

public extension AudioService {
    func playMessageIncoming() {
        playBundledSound(named: "rckit_incoming")
    }

    func playMessageOutgoing() {
        playBundledSound(named: "rckit_outgoing")
    }

    func playNotification() {
        playBundledSound(named: "notification")
    }

    func playTap() {
        playBundledSound(named: "tapp")
    }

    private func playBundledSound(named name: String) {
        guard let path = Bundle.main.path(
            forResource: name,
            ofType: "aiff"
        ) ?? Bundle.main.path(
            forResource: name,
            ofType: "wav"
        ) else {
            return
        }
        playSound(path)
    }
}
