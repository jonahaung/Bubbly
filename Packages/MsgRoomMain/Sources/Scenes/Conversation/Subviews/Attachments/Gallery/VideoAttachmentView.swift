//
//  VideoAttachmentView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 29/12/25.
//

import AVKit
import Database
import SwiftUI
import XUI

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

	private func togglePlayback() {
		guard let player else { return }
		switch player.timeControlStatus {
		case .playing:
			player.pause()
		case .paused, .waitingToPlayAtSpecifiedRate:
			player.play()
		@unknown default:
			player.play()
		}
	}
}
