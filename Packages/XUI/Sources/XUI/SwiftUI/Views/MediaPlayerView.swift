//
//  MediaPlayerView.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 30/1/23.
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
            .ignoresSafeArea()
            .onAppear {
                player.play()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
    }
}
