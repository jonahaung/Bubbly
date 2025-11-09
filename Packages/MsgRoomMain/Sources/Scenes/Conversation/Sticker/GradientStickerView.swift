//
//  GradientStickerView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 1/10/25.
//

import Services
import SwiftUI

struct GradientStickerView: View {
    @State var processedPhoto: Sticker
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: processedPhoto.colorScheme.colors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.7)
            .layoutPriority(-1)

            Image(uiImage: processedPhoto.sticker)
                .resizable()
                .scaledToFit()
        }
    }
}
