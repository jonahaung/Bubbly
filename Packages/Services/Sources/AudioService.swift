import AudioToolbox
import AVFoundation
import Foundation

public actor AudioService: Sendable {
    public static let shared = AudioService()

    private var players: [String: AVAudioPlayer] = [:]

    public init() {}

    public func playSound(_ path: String) {
		playSound(path, volume: 0.2)
    }

    public func playAlert(_ path: String) {
        playAlert(path, volume: 0.2)
    }

    public func playSound(_ path: String, volume: Float) {
        playSound(path, isAlert: false, volume: volume)
    }

    public func playAlert(_ path: String, volume: Float) {
        playSound(path, isAlert: true, volume: volume)
    }

    public func playVibrateSound() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    public func stopAllSounds() {
        for (path, player) in players {
            player.stop()
            players[path] = nil
        }
    }

    public func stopSound(_ path: String) {
        guard !path.isEmpty else { return }
        players[path]?.stop()
        players[path] = nil
    }

    private func playSound(_ path: String, isAlert: Bool, volume: Float) {
        guard !path.isEmpty else { return }
        let clampedVolume = max(0, min(1, volume))
        if let player = players[path] {
            player.volume = clampedVolume
            player.currentTime = 0
            player.play()
            return
        }
        guard FileManager.default.fileExists(atPath: path) else { return }
        let url = URL(fileURLWithPath: path)
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = clampedVolume
        player.prepareToPlay()
        players[path] = player
        player.play()
        if isAlert {
            player.volume = clampedVolume
        }
    }
}

public extension AudioService {
	enum Tone: String, Sendable {
		case tap1, tap2, tap3, tapSoft1, notification, msgOutgoing, msgIncoming, paper
	}
	func play(_ tone: Tone) {
		playBundledSound(named: tone.rawValue)
	}


    private func playBundledSound(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "aiff")
            ?? Bundle.main.url(forResource: name, withExtension: "wav")
        else {
            return
        }
        playSound(url.path)
    }
}
