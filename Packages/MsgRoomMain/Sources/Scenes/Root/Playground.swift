//
//  Playground.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/2/26.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct Playground: View {
	@State private var showModal = false
	let text = Lorem.random()
	@State private var fontName = ""
	var body: some View {
		List {
			Button("Show modal") {
				showModal = true
			}
			Button("Font Picker") {
				Router.shared.presnetModel(.view(FontPicker(selection: $fontName).opaqueView()))
			}
			Button("Markdown View") {
				Router.shared.presnetModel(.view(MarkdownView.ExampleView().opaqueView()))
			}
			Button("System Sounds") {
				Router.shared.presnetModel(.view(SystemSoundTesterView().opaqueView()))
			}
			Button("Show Toast") {
				ToastPresenter.show(allowsBackgroundTap: true) {
					Text(Lorem.random())
				} action: {
					print("tapped")
				}
			}
			Button("Show Loading") {
				Loading.show(true)
			}
			Label(text, systemImage: "bubble.right")
		}
		.navigationTitle("Playgound")
		.overlay {
			if showModal {
				ModalOverlay(.bottom, from: .bottom, allowsBackgroundTap: true) {
					Text(Lorem.random())
						.padding()
						.background(.bar, in: .rect)
						.colorScheme(.dark)
				} onClose: {
					showModal = false
				}
			}
		}
	}
}
