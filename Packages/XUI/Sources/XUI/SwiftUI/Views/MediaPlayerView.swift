//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import SwiftUI

public struct MediaPlayerView: View {
    private let player: AVPlayer
    @Environment(\.dismiss) private var dismiss

    public init(url: URL) {
        player = AVPlayer(url: url)
    }

    public var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player.play()
            }
    }
}
