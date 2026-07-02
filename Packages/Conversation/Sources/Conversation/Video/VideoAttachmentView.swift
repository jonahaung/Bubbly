//
//  VideoAttachmentView.swift
//  Conversation
//
//  Created by Aung Ko Min on 15/5/26.
//


import XUI
    import AVKit
    import SwiftUI
    import Database

    public struct VideoAttachmentView: View {
        let attachment: Attachment
        @State private var player: AVPlayer?

        init(attachment: Attachment) {
            self.attachment = attachment
        }

        public var body: some View {
            VideoPlayer(player: player) {
                if player?.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                    ProgressView().controlSize(.mini)
                }
            }
            .aspectRatio(attachment.aspectRatio, contentMode: .fit)
            .onAppear {
                if let url = URL(string: attachment.url) {
                    let newPlayer = AVPlayer(url: url)
                    player = newPlayer
                    newPlayer.play()
                }
            }
            .onDisappear {
                player?.pause()
            }
        }
    }