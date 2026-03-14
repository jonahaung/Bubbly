//
//  SoundEffect.swift
//  Core
//
//  Created by Aung Ko Min on 10/3/26.
//

import SwiftUI
import CoreHaptics
import UniformTypeIdentifiers
import AVFoundation

public struct SoundEffect: Hashable, Sendable {
	nonisolated(unsafe)
    static var audioSession: AVAudioSession?

    var urls: [URL]

    var url: URL? {
        return urls.first
    }

	var volume: Double = 0.7

	public init(_ names: String..., type: UTType = .audio, bundle: Bundle? = nil) {
        let bundle = bundle ?? .module
        let types: [UTType]
        if type == .audio {
            types = [type, .aiff, .wav, UTType(filenameExtension: "caf")!, .mpeg4Audio, UTType(filenameExtension: "m4a")!]
        } else {
            types = [type]
        }

        self.urls = []

        for type in types {
            let fileExtensions = type.tags[.filenameExtension] ?? []
            for fileExtension in fileExtensions {
                for name in names {
                    if let url = bundle.url(forResource: name, withExtension: fileExtension) {
                        self.urls.append(url)
                    }
                }
                if urls.count > 0 {
                    return
                }
            }
        }

        print("No sound resource named \(names.map({ "'\($0)'" }).formatted(.list(type: .and))) with type '\(type)' found in bundle \(bundle)")
    }

    public init(url: URL) {
        self.urls = [url]
    }
    public func volume(_ value: Double) -> Self {
        var copy = self
        copy.volume = value
        return copy
    }
}

