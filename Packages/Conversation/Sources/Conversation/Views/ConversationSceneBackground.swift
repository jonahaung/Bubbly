//
//  ConversationSceneBackground.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 14/2/26.
//

import SwiftUI

struct ConversationSceneBackground: View, Equatable {
	let color: Color

    var body: some View {
		color
			.overlay {
				Image("adaptive")
					.resizable(resizingMode: .tile)
					.foregroundStyle(
						AngularGradient(colors: Color.adaptableGrayColors, center: .topLeading)
					)
			}
			.backgroundExtensionEffect()
			.equatable(by: true)
    }
}
