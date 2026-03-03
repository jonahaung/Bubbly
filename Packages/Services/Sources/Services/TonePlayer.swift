//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import SwiftUI

@globalActor
public struct TonePlayerActor {
    public actor SomeActor {}
    public static let shared = SomeActor()
}

public enum Tone: String, Sendable {
    case tap1
    case tap2
    case tickTick
    case tapSoft1
    case notification
    case msgOutgoing
    case msgIncoming
    case paper

    public var volume: Float {
        switch self {
        case .tap1, .tap2, .tapSoft1:
            0.003
        case .tickTick:
            0.005
        case .notification, .msgOutgoing, .msgIncoming, .paper:
            0.05
        }
    }
}

public enum TonePlayer {
    @TonePlayerActor
    private static let player = TonePlayerImpl()

    public static func play(_ tone: Tone = .tap1) {
        Task { @TonePlayerActor in
            player.play(tone, volume: tone.volume)
        }
    }
}

@TonePlayerActor
final class TonePlayerImpl {
    private var players: [Tone: AVAudioPlayer] = [:]

    func play(_ tone: Tone, volume: Float) {
        let clamped = max(0, min(1, volume))
        if let player = players[tone] {
            player.volume = clamped
            player.currentTime = 0
            player.play()
            return
        }

        guard
            let url = Bundle.main.url(
                forResource: tone.rawValue,
                withExtension: "wav"
            )
            ?? Bundle.main.url(forResource: tone.rawValue, withExtension: "aiff")
        else {
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = clamped
            player.prepareToPlay()
            players[tone] = player
            player.play()
        } catch {
            return
        }
    }
}

public extension View {
    func playTone(_ tone: Tone) {
        TonePlayer.play(tone)
    }
}
