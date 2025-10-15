//
//  StickerView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 1/10/25.
//


import SwiftUI
import Services

struct StickerView: View {

    init(_ processedPhoto: Sticker?) {
        self.sticker = processedPhoto?.sticker
    }

	let sticker: UIImage?

    var body: some View {
        Group {
            if let sticker {
				Image(uiImage: sticker)
                    .resizable()
					.scaledToFit()
            } else {
                errorSticker
            }
        }
        .scaledToFit()
        .shadow(radius: 2)
    }

    @ViewBuilder
    var errorSticker: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .resizable()
            .padding(16)
            .foregroundStyle(.yellow)
    }
}
