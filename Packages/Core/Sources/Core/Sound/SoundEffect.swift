// © 2026 Aung Ko Min

import AVFoundation
import CoreHaptics
import SwiftUI
import UniformTypeIdentifiers

public struct SoundEffect: Hashable, Sendable {
    nonisolated(unsafe) static var audioSession: AVAudioSession? = nil

    var urls: [URL]

    var url: URL? {
        urls.first
    }

    var volume: Double = 0.7

    public init(_ names: String..., type: UTType = .audio, bundle: Bundle? = nil) {
        let bundle = bundle ?? .module
        let types: [UTType] =
            if type == .audio {
                [
                    type,
                    .aiff,
                    .wav,
                    UTType(filenameExtension: "caf")!,
                    .mpeg4Audio,
                    UTType(filenameExtension: "m4a")!,
                ]
            } else {
                [type]
            }

        urls = []

        for type in types {
            let fileExtensions = type.tags[.filenameExtension] ?? []
            for fileExtension in fileExtensions {
                for name in names {
                    if let url = bundle.url(forResource: name, withExtension: fileExtension) {
                        urls.append(url)
                    }
                }
                if !urls.isEmpty {
                    return
                }
            }
        }

        print(
            "No sound resource named \(names.map { "'\($0)'" }.formatted(.list(type: .and))) with type '\(type)' found in bundle \(bundle)",
        )
    }

    public init(url: URL) {
        urls = [url]
    }

    public init(sound: Sound) {
        self.init(sound.rawValue, type: .init("m4a")!)
    }

    public func volume(_ value: Double) -> Self {
        var copy = self
        copy.volume = value
        return copy
    }
}
